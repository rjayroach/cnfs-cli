# frozen_string_literal: true

class CommandsController < Thor

  private

  def run(command_name, args = {}, limits = {})
    if options[:help]
      invoke(:help, [command_name.to_s])
      return
    end

    # TODO: Implement are you sure? for k8s destroy and so all commands can leverage it

    controller_class = "#{self.class.name.gsub('Controller', '')}::#{command_name.to_s.camelize}Controller"
    unless (controller = controller_class.safe_constantize)
      raise Error, set_color("Class not found: #{controller_class} (this is a bug. please report)", :red)
    end

    args = Thor::CoreExt::HashWithIndifferentAccess.new(args.merge(options.slice(*options_to_args)))
    opts = Thor::CoreExt::HashWithIndifferentAccess.new(options.except(*options_to_args))
    Cnfs.context_name = args.context_name
    controller.new(args, opts).call
  end

  def options_to_args
    %w[context_name key_name target_name namespace_name application_name service_names profile_names tag_names]
  end

  # def params(method_name, method_binding)
  #   method(method_name).parameters.each_with_object({}) do |(_, name), hash|
  #     hash[name] = method_binding.local_variable_get(name)
  #   end
  # end
end