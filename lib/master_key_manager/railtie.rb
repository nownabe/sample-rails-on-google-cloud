module MasterKeyManager
  class Railtie < ::Rails::Railtie
    # See also https://github.com/rails/rails/blob/v6.1.4.4/activesupport/lib/active_support/railtie.rb#L67-L76
    initializer "master_key_manager.set_master_key", before: "active_support.require_master_key" do |app|
      if app.config.x.master_key_manager.secret_id
        require "google/cloud/secret_manager"

        client = Google::Cloud::SecretManager.secret_manager_service

        name = client.secret_version_path(
          project: app.config.x.master_key_manager.project_id,
          secret: app.config.x.master_key_manager.secret_id,
          secret_version: "latest",
        )

        ENV.store(
          "RAILS_MASTER_KEY",
          client.access_secret_version(name: name).payload.data,
        )
      end
    end
  end
end
