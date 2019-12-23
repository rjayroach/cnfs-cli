# frozen_string_literal: true

# deployment has many targets
# each target has one runtime
# each target has many layers
# deployment has one application
# application has many layers
# each layer has many services and resources

class ApplicationController < Thor

  private

  def run(command_name, args)
    if options[:help]
      invoke(:help, [command_name.to_s])
      return
    end

    deployment_name = options.deployment || ENV['CNFS_DEPLOY'] || :default
    unless (deployment = Deployment.find_by(name: deployment_name))
      raise Error, set_color("Deployment not found: #{deployment_name}", :red)
    end

    controller_class = "#{self.class.name.gsub('Controller', '')}::#{command_name.to_s.camelize}Controller"
    unless (controller = controller_class.safe_constantize)
      raise Error, set_color("Class not found: #{controller_class} (this is a bug. please report)", :red)
    end

    controller.new(deployment, args, options).call
  end
end