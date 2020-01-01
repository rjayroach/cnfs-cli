# frozen_string_literal: true

class ConsoleController < ApplicationController
  module Commands
    class << self
      def cache; @cache ||= {} end

      def reset_cache; @cache = nil end

      def load
        shortcuts.each_pair do |key, klass|
          define_method("#{key}a") { klass.all }
          define_method("#{key}f") { ConsoleController::Commands.cache["#{key}f"] ||= klass.first }
          define_method("#{key}l") { ConsoleController::Commands.cache["#{key}l"] ||= klass.last }
        end
        TOPLEVEL_BINDING.eval('self').extend(self)
      end

      def shortcuts
        { d: Deployment, a: Application, t: Target, r: Resource, s: Service, p: Provider }
      end
    end
  end

  def execute(input: $stdin, output: $stdout)
    Pry::Commands.block_command 'r', 'Reload', keep_retval: true do |*args|
      ConsoleController::Commands.reset_cache
      Cnfs.reload
    end
    # TODO: Alias 'r' above to this command
    Pry::Commands.block_command 'reload!', 'Reload', keep_retval: true do |*args|
      ConsoleController::Commands.reset_cache
      Cnfs.reload
    end
    ConsoleController::Commands.load
    Pry.start
  end
end
