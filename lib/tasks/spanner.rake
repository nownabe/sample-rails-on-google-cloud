require "google/cloud/spanner"

namespace :spanner do
  namespace :instance do
    task :create => :environment do
      config = ActiveRecord::Base.configurations.find_db_config(Rails.env).configuration_hash
      spanner = Google::Cloud::Spanner.new(
        project_id: config[:project],
        emulator_host: config[:emulator_host],
      )
      job = spanner.create_instance(config[:instance])
      job.wait_until_done!
      p job.error if job.error?
    end
  end
end
