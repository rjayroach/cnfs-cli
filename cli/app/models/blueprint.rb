# frozen_string_literal: true

# A Blueprint is analagous to a TF Module, but module is a reserved keyword in ruby
class Blueprint < Component
  def dir_path
    parent.rootpath.split.first.join('config')
  end

  # Called by Node::ComponentDir in order to load any defined classes before it loads #paths
  def before_load_path(rootpath, cdir)
    component_config_file = rootpath.join('../blueprint.yml')
    if component_config_file&.exist? && (component_config = YAML.load_file(component_config_file))
      update(config: component_config.merge(config))
    end

    Cnfs.add_loader(name: name, path: rootpath.join('../app')).setup
  end

  def tree_name
    "#{name} (#{type})"
  end

  # List of resource classes that are managed by this blueprint
  def resource_classes
    []
  end

  # Used by builder to set the template's context to this blueprint
  def _binding
    binding
  end

  class << self
    def available_types(platform)
      defined_types.select { |p| p.start_with?(platform.to_s) }.map { |p| p.split('/').second }.sort
    end

    def available_platforms
      defined_types.map { |p| p.split('/').first }.uniq.sort
    end

    def defined_types
      @defined_types ||= defined_files.select { |p| p.split('/').size > 1 }.map { |p| p.delete_suffix('.rb') }
    end

    def defined_files
      # CnfsCli.plugins.values.map(&:to_s).sort.each_with_object([]) do |p, ary|
      CnfsCli.plugins.values.each_with_object([]) do |p, ary|
        path = p.gem_root.join('app/models/blueprint')
        next unless path.exist?

        Dir.chdir(path) { ary.concat(Dir['**/*.rb']) }
      end
    end

    def add_columns(t)
      t.string :environment_name
      t.references :environment
      t.string :provider_name
      t.references :provider
      t.string :provisioner_name
      t.references :provisioner
    end
  end
end
