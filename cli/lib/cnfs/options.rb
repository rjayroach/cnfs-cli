# frozen_string_literal: true

module Cnfs
  module Options
    extend ActiveSupport::Concern

    included do |base|
      # unless %w[new version].include?(ARGV[0]) or (ARGV[0]&.eql?('help') and %w[new version].include?(ARGV[1]))
      class_option :environment, desc: 'Target environment',
        aliases: '-e', type: :string, default: Cnfs.config.environment if base::OPTS.include?(:env)
      class_option :namespace, desc: 'Target namespace',
        aliases: '-n', type: :string, default: Cnfs.config.namespace if base::OPTS.include?(:ns)
      class_option :force, desc: 'Do not prompt for confirmation',
        aliases: '-f', type: :boolean if base::OPTS.include?(:force)
      class_option :fail_fast,  desc: 'Skip any remaining commands after a command fails',
        aliases: '--ff', type: :boolean if base::OPTS.include?(:fail_fast)
      # end

      class_option :debug, desc: 'Display deugging information with degree of verbosity',
        aliases: '-d', type: :numeric, default: Cnfs.config.debug if base::OPTS.include?(:debug)
      class_option :noop, desc: 'Do not execute commands',
        type: :boolean, default: Cnfs.config.noop if base::OPTS.include?(:noop)
      class_option :quiet, desc: 'Suppress status output',
        aliases: '-q', type: :boolean, default: Cnfs.config.quiet if base::OPTS.include?(:quiet)
      # class_option :tag, type: :string
      class_option :verbose, desc: 'Display extra information from command',
        aliases: '-v', type: :boolean, default: Cnfs.config.verbose if base::OPTS.include?(:verbose)
    end
  end
end
