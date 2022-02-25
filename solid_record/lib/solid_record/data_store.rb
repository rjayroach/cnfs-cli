# frozen_string_literal: true

module SolidRecord
  class << self
    # Path to a file that defines an ActiveRecord::Schema
    attr_accessor :schema_file
  end

  class DataStore
    class << self
      def load(*paths)
        ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
        reload(paths)
      end

      def reload(*paths)
        ActiveRecord::Migration.verbose = defined?(SPEC_ROOT) ? false : SolidRecord.logger.level.eql?(0)
        SolidRecord.schema_file ? load(schema_file) : create_schema_from_tables
        paths.flatten.each { |path| SolidRecord::Element.create_from_path(path) }
        true
      end

      def create_schema_from_tables
        ActiveRecord::Schema.define do |schema|
          require_relative '../ext/table_definition'
          SolidRecord.tables.select { |table| table.respond_to?(:create_table) }.each do |table|
            table.create_table(schema)
            table.reset_column_information
          end
        end
      end

      # Dump the latest version of the schema to a file
      #
      # Create a schema which can be used with NullDB to emulate models without having
      # the actual classes or underlying database prsent
      def schema_dump(file_name = nil)
        schema = ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, StringIO.new).string
        return schema unless file_name

        File.open(file_name, 'w') { |f| f.puts(schema) }
      end
    end
  end
end
