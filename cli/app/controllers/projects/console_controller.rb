# frozen_string_literal: true

require 'pry'

class Console < Pry::ClassCommand
  match 'commands'
  group 'cnfs'
  description 'List commands available in the current command set'

  def process(_command_set)
    if target_self.class.name.eql?('Projects::ConsoleController')
      puts "#{target_self.class.commands.join("\n")}\n\nreload!"
    else
      puts target_self.class.instance_methods(false).join("\n")
    end
  end
end

CnfsCommandSet = Pry::CommandSet.new
CnfsCommandSet.add_command(Console)
Pry.config.commands.import CnfsCommandSet

module Projects
  class ConsoleController
    include ExecHelper

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def execute
      Cnfs.config.is_cli = true
      project = Pry::Helpers::Text.blue(Cnfs.project.name)
      env = Cnfs.project.environment.name
      environment_color = env.eql?('production') ? 'red' : env.eql?('staging') ? 'yellow' : 'green'
      environment = Pry::Helpers::Text.send(environment_color, env)
      namespace = Cnfs.project.namespace.name
      prompt = proc do |obj, _nest_level, _|
        "[#{project}][#{environment}][#{namespace}] " \
          "(#{Pry.view_clip(obj.class.name.demodulize.delete_suffix('Controller').underscore).gsub('"', '')})> "
      end
      Pry.config.prompt = Pry::Prompt.new('cnfs', 'cnfs prompt', [prompt])
      Pry.start(self)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    class << self
      def shortcuts
        return {} unless defined?(ActiveRecord)

        { b: Builder, bl: Blueprint, d: Dependency, e: Environment, n: Namespace, pr: Provider,
          res: Resource, reg: Registry, rep: Repository, run: Runtime, s: Service, u: User }
      end

      def commands
        %i[projects repositories infra environments blueprints namespaces images services]
      end
    end

    commands.each do |command_set|
      define_method(command_set) do
        Pry.start("#{command_set}_controller".classify.safe_constantize.new(args, options))
        true
      end
    end

    shortcuts.each_pair do |key, klass|
      define_method(key) { klass } unless %w[p r].include?(key)
      define_method("#{key}a") { klass.all }
      define_method("#{key}f") { cache["#{key}f"] ||= klass.first }
      define_method("#{key}l") { cache["#{key}l"] ||= klass.last }
      define_method("#{key}p") { |*attributes| klass.pluck(*attributes) }
      define_method("#{key}fb") { |name| klass.find_by(name: name) }
    end

    def cache
      @cache ||= {}
    end

    def reset_cache
      @cache = nil
    end

    def reload!
      reset_cache
      Cnfs.reload
      true
    end

    def r
      reload!
    end

    def m
      project.manifest
    end

    def o
      options
    end

    def t
      cache[:t] ||= Runtime::Infra::Terraform.new
    end

    def g
      cache[:g] ||= t.generator
    end

    def oa(opts = {})
      options.merge!(opts)
    end

    def od(key)
      @options = Thor::CoreExt::HashWithIndifferentAccess.new(options.except(key.to_s))
      options
    end
  end
end
