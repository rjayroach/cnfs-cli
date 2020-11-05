# frozen_string_literal: true

module Primary
  class ShellController < ApplicationController
    def execute
      run(:build) if options.build
      application.exec(application.service, application.service.shell_command, true)
    end
  end
end
