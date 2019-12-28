# frozen_string_literal: true

module App::Backend
  class GenerateController < Cnfs::Command
    def execute
      each_target do |target|
        # before_execute_on_target
        execute_on_target
      end
    end

    def execute_on_target
      generator = generator_class.new(args, options)
      generator.deployment = deployment
      generator.application = deployment.application
      generator.target = target
      generator.write_path = Pathname.new(target.write_path(:deployment))
      generator.invoke_all
    end

    def generator_class; "#{target.runtime.type.demodulize}Generator".safe_constantize end
  end
end
