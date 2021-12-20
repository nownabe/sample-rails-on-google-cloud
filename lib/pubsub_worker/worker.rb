require "json"

require "rails"
require "active_job/arguments"

module PubsubWorker
  class Worker
    class InvalidJobError < StandardError; end
    class InvalidMessageError < StandardError; end

    def initialize(queue:)
      @queue = queue
      @termination = Queue.new

      logger.info("Initializing #{inspect}")

      require File.expand_path("../../config/environment.rb", __dir__)
      Rails.logger = logger

      # Shutdown gracefully
      Signal.trap(:TERM) { terminate! }
      Signal.trap(:INT) { terminate! }
    end

    def start
      subscriber.start
      logger.info("Started #{inspect}")

      wait_for_signal

      logger.info("Shutting down #{inspect}...")

      # Wait until all received messages have been processed or released
      subscriber.stop.wait!

      logger.info("Exiting #{inspect}")
    end

    private

    def format_job(job)
      "#{job.class} (Job ID: #{job.job_id}) with arguments: #{job.arguments}"
    rescue => e
      raise InvalidJobError, "failed to format job: #{e.class}: #{e.message}"
    end

    def handle(message)
      job = parse_message_as_job(message)

      logger.info("Started #{format_job(job)}")
      job.perform(*job.arguments)
    rescue InvalidJobError, InvalidMessageError => e
      logger.error("Failed job: #{e.class}: #{e.message}")
    rescue => e
      logger.error("Error #{format_job(job)}:#{e.class}: #{e.message}")
    else
      logger.info("Finished #{format_job(job)}")
      message.acknowledge!
    end

    def inspect
      "#<#{self.class} @queue=\"#{@queue}\">"
    end

    def logger
      return @logger if @logger

      logger = ActiveSupport::Logger.new(STDOUT)
      logger.formatter = ::Logger::Formatter.new
      @logger = ActiveSupport::TaggedLogging.new(logger)
    end

    def parse_message_as_job(message)
      serialized_job = JSON.parse(message.message.data)
      arguments = ActiveJob::Arguments.deserialize(serialized_job["arguments"])
      job = serialized_job["job_class"].constantize.new(*arguments)
      job.deserialize(serialized_job)

      job
    rescue => e
      raise InvalidMessageError, "failed to parse message #{message.message.data}: #{e.class}: #{e.message}"
    end

    def pubsub
      @pubsub ||= Google::Cloud::Pubsub.new(
        project: ENV.fetch("GOOGLE_CLOUD_PROJECT"),
      )
    end

    def subscriber
      @subscriber ||= subscription.listen do |message|
        handle(message)
      end
    end

    def subscription
      @subscription ||= pubsub.subscription("#{@queue}-worker")
    end

    def terminate!
      @termination << true
    end

    def wait_for_signal
      @termination.pop
    end
  end
end
