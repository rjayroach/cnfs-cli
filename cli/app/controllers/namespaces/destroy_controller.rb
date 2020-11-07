# frozen_string_literal: true

module Namespaces
  class DestroyController < ApplicationController
    cattr_reader :command_group, default: :cluster_admin

    def execute
      context.each_target do
        before_execute_on_target
        execute_on_target
      end
    end

    def execute_on_target
      context.runtime.destroy.run!
    end
  end
end
