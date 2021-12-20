require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative "../lib/master_key_manager/railtie"
require_relative "../lib/active_job/queue_adapters/pubsub_adapter"

module MyApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.active_job.queue_adapter = :pubsub

    # See lib/master_key_manager/railtie.rb
    config.x.master_key_manager.secret_id = ENV.fetch("MASTER_KEY_SECRET_ID", nil)
    config.x.master_key_manager.project_id = ENV.fetch("GOOGLE_CLOUD_PROJECT")
  end
end
