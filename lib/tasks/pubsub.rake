require "google/cloud/pubsub"

namespace :pubsub do
  namespace :topic do
    task :create, ['topic'] => :environment do |_, args|
      pubsub = Google::Cloud::PubSub.new(project: ENV.fetch("GOOGLE_CLOUD_PROJECT"))
      next if pubsub.topic(args[:topic])
      topic = pubsub.create_topic(args[:topic])
      topic.subscribe("#{args[:topic]}-worker")

      puts "Created #{args[:topic]} topic"
    end
  end
end
