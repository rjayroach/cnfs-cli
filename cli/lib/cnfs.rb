# frozen_string_literal: true

require 'active_record'
require 'active_record/fixtures'
require 'active_support/inflector'
require 'active_support/string_inquirer'
require 'config'
# require 'json_schemer'
require 'little-plugger'
require 'lockbox'
require 'open-uri'
require 'pry'
# require 'open3'
require 'sqlite3'
require 'thor'
require 'xdg'
require 'zeitwerk'

require_relative 'ext/config/options'
require_relative 'ext/string'
require_relative 'cnfs/schema'
require_relative 'cnfs/errors'
require_relative 'cnfs/version'

Config.setup do |config|
  config.use_env = true
  config.env_separator = '_'
  config.env_prefix = 'CNFS'
end

module Cnfs
  extend LittlePlugger
  module Plugins; end

  class Error < StandardError; end

  class << self
    attr_accessor :autoload_dirs, :current_context_name
    attr_reader :root, :config_path, :config_file, :user_root, :user_config_path
    attr_reader :project_name

    def setup(skip_schema = false)
      setup_paths(Dir.pwd)
      initialize_plugins
      setup_loader
      Schema.setup unless skip_schema
    end

    def setup_paths(project_path)
      @root = Pathname.new(project_path)
      @config_path = root.join('config')
      @config_file = root.join('.cnfs')

      return unless File.exist? config_file

      @project_name = File.read(config_file).chomp
      @user_root = xdg.config_home.join('cnfs').join(project_name)
      @user_config_path = user_root.join('config')
    end

    def current_context; Context.find_by(name: current_context_name) end

    def current_context_name; @current_context_name || ENV['CNFS_CONTEXT'] || :default end

    def project?; File.exist?(config_file) end

    # NTOE: Dir.pwd is the current application's root (switched into)
    # TODO: This should probably move out to rails or some other place
    def services_project?; File.exist?(Pathname.new(Dir.pwd).join('lib/core/lib/ros/core.rb')) end

    def gem_config_path; @gem_config_path ||= gem_root.join('config') end

    def gem_root; @gem_root ||= Pathname.new(__dir__).join('..') end

    def xdg; @xdg ||= XDG::Environment.new end

    def debug; ARGV.include?('-d') ? ARGV[ARGV.index('-d') + 1].to_i : 0 end

    # Zeitwerk based class loader methods
    def setup_loader
      Zeitwerk::Loader.default_logger = method(:puts) if debug > 1
      autoload_dirs.each { |dir| loader.push_dir(dir) }

      loader.enable_reloading
      loader.setup
    end

    def reload
      Schema.reload
      loader.reload
    end

    def loader; @loader ||= Zeitwerk::Loader.new end

    def autoload_dirs; @autoload_dirs ||= ["#{gem_root}/app/controllers", "#{gem_root}/app/models", "#{gem_root}/app/generators"] end

    # Utility methods
    # Configuration fixture file loading methods
    def config_content(type, file)
      fixture_file = fixture(type, file)
      if File.exist?(fixture_file)
        STDOUT.puts "Loading config file #{fixture_file}" if debug > 0
        ERB.new(IO.read(fixture_file)).result.gsub("---\n", '')
      end
    end

    def fixture(type, file)
      replace_path = type.to_sym.eql?(:project) ? config_path : user_config_path
      file.gsub(gem_config_path.to_s, replace_path.to_s)
    end

    # Lockbox encryption methods
    def box; @box ||= Lockbox.new(key: box_key) end

    def box_key
      return ENV['CNFS_MASTER_KEY'] if ENV['CNFS_MASTER_KEY']
      File.read(box_file).chomp if File.exist?(box_file)
    end

    def box_file; user_root.join('credentials') end

    # OS methods
    def gid
      ext_info = OpenStruct.new
      if (RbConfig::CONFIG['host_os'] =~ /linux/ and Etc.getlogin)
        shell_info = Etc.getpwnam(Etc.getlogin)
        ext_info.puid = shell_info.uid
        ext_info.pgid = shell_info.gid
      end
      ext_info
    end
  end
end
