# frozen_string_literal: true

module Cnfs
  class Schema
    def self.setup
      # Set up in-memory database
      ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
      ActiveSupport::Inflector.inflections do |inflect|
        inflect.uncountable %w[dns kubernetes postgres redis rails]
      end
      load_data
    end

    def self.reload
      # Enable fixtures to be re-seeded on code reload
      ActiveRecord::FixtureSet.reset_cache
      load_data
    end

    def self.load_data
      show_output = Cnfs.debug > 0
      Cnfs.silence_output(!show_output) { create_schema }
      dir = Cnfs.gem_config_path
      fixtures = Dir.chdir(dir) { Dir['**/*.yml'] }.map { |f| f.gsub('.yml', '') }
      ActiveRecord::FixtureSet.create_fixtures(dir, fixtures)
    end

    # Set up database tables and columns
    def self.create_schema
      ActiveRecord::Schema.define do
        create_table :contexts, force: true do |t|
          t.references :application
          t.references :target
          t.string :namespace
          t.string :name
          t.string :services
          t.string :resources
          t.string :tags
        end
        Context.reset_column_information

        create_table :keys, force: true do |t|
          t.string :name
          t.string :value
        end
        Key.reset_column_information

        create_table :applications, force: true do |t|
          t.string :name
          t.string :config
          t.string :environment
          t.string :type
          t.string :path
        end
        Application.reset_column_information

        create_table :targets, force: true do |t|
          t.references :runtime
          t.references :infra_runtime
          t.references :provider
          t.string :name
          t.string :config
          t.string :tf_config
          t.string :environment
          t.string :type
          t.string :namespaces
        end
        Target.reset_column_information

        create_table :deployments, force: true do |t|
          t.references :application
          t.references :target
          t.references :key
          t.string :name
          t.string :config
          t.string :environment
          t.string :service_environments
        end
        Deployment.reset_column_information

        create_table :providers, force: true do |t|
          t.string :name
          t.string :config
          t.string :environment
          t.string :type
          t.string :kubernetes
        end
        Provider.reset_column_information

        create_table :runtimes, force: true do |t|
          t.string :name
          t.string :config
          t.string :environment
          t.string :type
        end
        Runtime.reset_column_information

        create_table :resources, force: true do |t|
          t.string :name
          t.string :config
          t.string :environment
          t.string :resources
          t.string :type
          t.string :template
        end
        Resource.reset_column_information

        create_table :services, force: true do |t|
          t.string :name
          t.string :config
          t.string :environment
          t.string :type
          t.string :template
          t.string :path
        end
        Service.reset_column_information

        create_table :tags, force: true do |t|
          t.string :name
          t.string :description
          t.string :config
          t.string :environment
        end
        Tag.reset_column_information

        create_table :target_services, force: true do |t|
          t.references :target
          t.references :service
        end
        TargetService.reset_column_information

        create_table :target_resources, force: true do |t|
          t.references :target
          t.references :resource
        end
        TargetResource.reset_column_information

        create_table :application_services, force: true do |t|
          t.references :application
          t.references :service
        end
        ApplicationService.reset_column_information

        create_table :application_resources, force: true do |t|
          t.references :application
          t.references :resource
        end
        ApplicationResource.reset_column_information

        create_table :resource_tags, force: true do |t|
          t.references :resource
          t.references :tag
        end
        ResourceTag.reset_column_information

        create_table :service_tags, force: true do |t|
          t.references :service
          t.references :tag
        end
        ServiceTag.reset_column_information
      end
    end
  end
end
