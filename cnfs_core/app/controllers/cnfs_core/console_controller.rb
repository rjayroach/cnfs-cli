# frozen_string_literal: true

require 'pry'

class Console < Pry::ClassCommand
  match 'commands'
  group 'cnfs'
  description 'List commands available in the current command set'

  # rubocop:disable Metrics/AbcSize
  def process(_command_set)
    # if target_self.instance_of?(CnfsCore::ConsoleController)
    if target_self.class.respond_to?(:add_commands)
      puts "#{target_self.class.commands.join("\n")}\n\n#{target_self.class.add_commands.join("\n")}"
    else
      puts target_self.class.instance_methods(false).join("\n")
    end
  end
  # rubocop:enable Metrics/AbcSize
end

CnfsCommandSet = Pry::CommandSet.new
CnfsCommandSet.add_command(Console)
Pry.config.commands.import CnfsCommandSet

module CnfsCore
  class ConsoleController
    def execute
      run_callbacks :execute do
        Cnfs.config.is_console = true
        Pry.config.prompt = Pry::Prompt.new('cnfs', 'cnfs prompt', [__prompt])
        self.class.reload
        Pry.start(self)
      end
    end

    class << self
      def add_commands
        %i[reload!]
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def reload
        commands.each do |command|
          define_method(command) do
            Pry.start("#{command.to_s.pluralize}_controller".classify.safe_constantize.new)
            true
          end
        end

        shortcuts.each_pair do |key, klass|
          define_method("#{key}a") { klass.all }
          define_method("#{key}c") { |**attributes| klass.create(attributes) }
          define_method("#{key}f") { cache["#{key}f"] ||= klass.first }
          define_method("#{key}fi") { |id| klass.find(id) }
          define_method("#{key}fn") { |name| klass.find_by(name: name) }
          define_method("#{key}k") { klass }
          define_method("#{key}l") { cache["#{key}l"] ||= klass.last }
          define_method("#{key}p") { |*attributes| klass.pluck(*attributes) }
          define_method("#{key}w") { |**attributes| klass.where(attributes) }
        end
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      def shortcuts
        return {} unless defined?(ActiveRecord)

        shortcuts = model_shortcuts
        ActiveSupport::Notifications.instrument 'add_console_shortcuts.cnfs', { shortcuts: shortcuts }
        shortcuts
      end
    end

    def cache
      @cache ||= {}
    end

    def reset_cache
      @cache = nil
    end

    def reload!
      reset_cache
      Cnfs.plugin_root.reload
      self.class.reload
      true
    end

    def r
      reload!
    end

    def o
      options
    end

    def oa(opts = {})
      options.merge!(opts)
    end

    def od(key)
      @options = Thor::CoreExt::HashWithIndifferentAccess.new(options.except(key.to_s))
      options
    end

    def method_missing(method)
      puts "Invalid command '#{method}'"
    end

    # https://www.rubydoc.info/gems/rubocop/RuboCop/Cop/Style/MissingRespondToMissing
    def respond_to_missing?(method_name, *args)
      method == :bark || super
    end
  end
end
