# frozen_string_literal: true

require 'active_model'

module Hendrix
  class ApplicationController
    extend ActiveModel::Callbacks
    include ActiveModel::AttributeAssignment

    # Load modules to add options, actions and sub-commands to existing command structure
    # include Hendrix::Extendable
    # include Extendable

    attr_accessor :options, :args, :command

    define_model_callbacks :execute

    # Define methods for each Command on Controllers so they can invoke methods in the command classes
    # e.g. execute_image(:build, *services) => Image::CommandController#build
    module_parent::MainCommand.all_commands.keys.each do |cmd|
      define_method("execute_#{cmd}") do |*args|
        module_parent::MainCommand.new.send(cmd.to_sym, *args)
      end
    end

    def initialize(**kwargs) = assign_attributes(**kwargs)

    # This method is invoked from Hendrix::Concerns::CommandController execute method
    # and invokes the target method wrapped in any defined callbacks
    def base_execute(method) = run_callbacks(:execute) { send(method) }

    # Implement with an around_execute :timer call in the controller
    def timer(&block) = Hendrix.with_timer('Command execution', &block)

    def parent_name = parent.to_s.underscore

    def parent = self.class.module_parent
  end
end
