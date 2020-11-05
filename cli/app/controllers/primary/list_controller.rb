# frozen_string_literal: true

module Primary
  class ListController < ApplicationController
    def execute
      require 'tty-tree'
      filters = Cnfs.project.arguments.filters
      filters = mapping.keys if filters.empty?
      filters.each do |filter|
        if (method = mapping[filter[0].to_sym])
          send(method)
          next
        end
        # response.output.puts 'Valid options are: config, ns, contexts, deployments, applications'
        response.output.puts 'Valid options are: environments, repositories'
      end
    end

    def mapping
      {
        e: :environments,
        r: :repositories
      }
    end

    def environments
      # response.output.puts Target.all.pluck(:name).sort
      response.output.puts Cnfs.paths.config.join('environments').children.select{ |e| e.directory? }.map(&:to_s)
    end

    def repositories
      response.output.puts Cnfs.paths.src.children.select{ |e| e.directory? }.map(&:to_s)
    end

    def execute_config
      binding.pry
      response.output.puts Cnfs.application.config.map { |key, value| "#{key}: #{value}\n" }
    end

    # def execute_ns
    #   each_target do
    #     before_execute_on_target
    #     if runtime.respond_to?(:run)
    #       runtime.run('get ns', pty: true).run!
    #     else
    #       # TODO: the only use of runtime.run is in skaffold to 'get ns' so this
    #       # will need to be refactored if/when that changes
    #       output.puts "Selected target #{target.name} does not support namespaces"
    #     end
    #   end
    # end
    # Service.joins(:tags).where(tags: {name: Tag.last.name})

    # def execute_contexts
    #   data = Context.all.each_with_object({}) do |profile, hash|
    #     item = []
    #     item.append("target: #{profile.target.name}") if profile.target
    #     item.append("namespace: #{profile.namespace}") if profile.namespace
    #     item.append("application: #{profile.application.name}") if profile.application
    #     %w[resources services].each do |attribute|
    #       item.append("#{attribute}: #{YAML.safe_load(profile.send(attribute)).join(', ')}") if profile.send(attribute)
    #     end
    #     hash[profile.name] = item unless item.empty?
    #   end
    #   output.puts(TTY::Tree.new(data).render)
    # end

    # def execute_deployments
    #   data = deployments(cli_args).each_with_object({}) do |deployment, hash|
    #     item = deploy_hash(deployment)
    #     hash[deployment.name] = item unless item.empty?
    #   end
    #   output.puts(TTY::Tree.new(data).render)
    # end

    def deploy_hash(deployment)
      result = {}
      unless ta_hash(deployment.target).empty?
        result["target (#{deployment.target.provider.type})"] = ta_hash(deployment.target)
      end
      result[:application] = ta_hash(deployment.application) unless ta_hash(deployment.application).empty?
      result
    end

    def ta_hash(ta)
      result = {}
      services = ta.services
      services = services.where(name: cli_args.service_names) if cli_args.service_names
      result[:services] = services.pluck(:name) if services.size.positive?
      resources = ta.resources
      resources = [] if cli_args.service_names
      result[:resources] = resources.pluck(:name) if resources.size.positive?
      result
    end
  end
end
