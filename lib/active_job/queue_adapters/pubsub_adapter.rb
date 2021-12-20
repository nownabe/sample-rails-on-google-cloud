require "json"

require "google/cloud/pubsub"

module ActiveJob
  module QueueAdapters
    class PubsubAdapter
      def enqueue(job)
        topic = client.topic(job.queue_name)
        message = topic.publish(job.serialize.to_json)
        job.provider_job_id = message.message_id
      end

      private

      def client
        @client ||= Google::Cloud::Pubsub.new(project: ENV.fetch("GOOGLE_CLOUD_PROJECT"))
      end
    end
  end
end
