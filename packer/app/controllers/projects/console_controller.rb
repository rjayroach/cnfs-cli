# frozen_string_literal: true

module Projects
  class ConsoleController < ConsoleControllerBase
    class << self
      def commands
        %i[]
      end

      def shortcuts
        { b: Build, bu: Builder, pu: Push }
      end
    end

    def pc
      cache[:pc] ||= Packer::Config.new 'test.json'
    end

    def __prompt
      project = Pry::Helpers::Text.blue(Cnfs.project.name)
      proc do |obj, _nest_level, _|
        "[#{project}] " \
          "(#{Pry.view_clip(obj.class.name.demodulize.delete_suffix('Controller').underscore).gsub('"', '')})> "
      end
    end
  end
end
