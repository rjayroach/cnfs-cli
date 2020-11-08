# frozen_string_literal: true

class ProjectController < CommandsController
  OPTS = %i[noop quiet verbose]
  include Cnfs::Options

  register Project::SetController, 'set', 'set [SUBCOMMAND]', 'Set a project configuration value'

  desc 'config', 'Display project configuration'
  option :local, desc: 'Display local overrides',
    aliases: '-l', type: :boolean
  def config(name = nil)
    YAML.load_file('cnfs.yml').each do |key, value|
      puts "#{key}: #{value}"
    end
  end

  desc 'console', 'Start a CNFS project console (short-cut: c)'
  option :environment, desc: 'Target environment',
    aliases: '-e', type: :string, default: Cnfs.config.environment
  option :namespace, desc: 'Target namespace',
    aliases: '-n', type: :string, default: Cnfs.config.namespace
  map %w[c] => :console
  def console
    run(:console)
  end

  desc 'init', 'Initialize the project'
  long_desc <<-DESC.gsub("\n", "\x5")

  The 'cnfs init' command initializes a newly cloned CNFS project with the following operations:

  Clone repositories
  Check for dependencies
  DESC
  def init
    run(:init)
  end

  desc 'customize', 'Customize project templates'
  def customize
    Cnfs.invoke_plugins_wtih(:customize)
  end
end