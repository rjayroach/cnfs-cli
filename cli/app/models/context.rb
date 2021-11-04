# frozen_string_literal: true

class Context < ApplicationRecord
  # Root can be a Project or Reppsitory Component, etc
  belongs_to :root, class_name: 'Component'
  has_many :context_components
  has_many :components, through: :context_components

  # dynamic methods for all asset types:
  # component_<asset> All <assets> from the component hierarchy
  # <asset> All <assets> that are available given the value of abstract at each level
  # filtered_<asset> All available <assets> filterd by arguments provided by the cli
  # <asset>_runtime The runtime object for the <asset>

  CnfsCli.asset_names.each do |asset_name|
    has_many "component_#{asset_name}".to_sym, through: :components, source: asset_name.to_sym
    has_many asset_name.to_sym, as: :owner

    # For each asset there is a filtered_<asset_name> method that returns an A/R assn
    # with a where clause if any args were passed in
    define_method "filtered_#{asset_name}".to_sym do
      args_plural = args.send(asset_name)
      args_singular = args.send(asset_name.singularize)
      # TODO: This is probably a bug. If args_plural is empty then it should probably return
      # an empty array
      if args_plural&.any?
        send(asset_name).where(name: args_plural)
      elsif args_singular
        send(asset_name).where(name: args_singular)
      else
        send(asset_name)
      end
    end

    # define_method "#{asset_name}_runtime".to_sym do |assets: send("filtered_#{asset_name}".to_sym)|
    #   runtime = component.runtime
    #   runtime.send("#{asset_name}=".to_sym, assets) #services = services
    #   runtime.context = self
    #   runtime
    # end
  end

  after_create :follow_components, :set_assets, if: proc { root_id }

  # The farthest leaf component found given the supplied options
  def component
    @context ||= components.order(:id).last
  end

  store :options, coder: YAML
  store :args, coder: YAML

  def options
    Thor::CoreExt::HashWithIndifferentAccess.new(super)
  end

  def args
    Thor::CoreExt::HashWithIndifferentAccess.new(super)
  end

  # Select the compoenents based on project and user supplied values
  # Update the component hierarchy tree
  # 1. Select from cli options
  # 2. Select from an ENV found in CNFS_component_name
  # 3. Select from a default set in project.yml
  #
  # The controller should call:
  # Project.first.contexts.create(root: Project.first, options: options)
  def follow_components
    current = root
    while current.components.any? do
      name, source = value(current)
      if (new_comp = current.components.find_by(name: name))
        components << new_comp
        current = new_comp
      else
        Cnfs.logger.warn("#{current.child_name.capitalize} '#{name}' configured from *#{source}* not found.\n" \
                         "#{' ' * 10 }Current context set to #{current.class.name} '#{current.name}'")
        break
      end
    end
  end

  def value(component)
    source = if (name = options.fetch(component.child_name, nil))
               'CLI option'
             elsif (name = Cnfs.config.send(component.child_name || ''))
               'ENV'
             elsif (name = component.default)
               component.parent.rootpath.basename
             end
    [name, source]
  end

  # TODO: Change the name of this method
  # TODO: What about tags?
  # @options.merge!('tags' => Hash[*options.tags.flatten]) if options.tags
  def set_assets
    CnfsCli.asset_names.each do |asset_type|
      component_assn = component.send(asset_type.to_sym).where(abstract: [false, nil])
      # binding.pry if asset_type.eql?('users')
      next unless component_assn.count.positive?

      owner_assn = send("component_#{asset_type}".to_sym).where(abstract: true).order(:id)
      assn = send(asset_type.to_sym)

      component_assn.each do |asset|
        json = owner_assn.where(name: asset.name).each_with_object({}) do |rec, hash|
          # json_hash = rec.as_json.compact
          # hash.deep_merge!(rec.as_json.compact)
          hash.merge!(rec.as_json.merge('name' => rec.name).compact)
        end
        json.merge!(asset.as_json.merge('name' => asset.name).compact).except!('id', 'owner_id', 'owner_type', 'abstract')
        # binding.pry if asset_type.eql?('runtimes')
        # json.deep_merge!(asset.as_json.compact).except!('id', 'owner_id', 'owner_type', 'abstract')
        # binding.pry if asset_type.eql?('users')
        assn.create(json.merge(skip_node_create: true))
      end
    end
  end

  def runtime(services: filtered_services)
    runtime = component.runtime
    runtime.services = services
    runtime.context = self
    runtime
  end

  # TODO: add other dirs for config files, e.g. gem user's path; load from a config file?
  # TODO: should only be one runtime per context
  def manifest
    @manifest ||= Manifest.new(config_files_paths: [path(to: :config)], write_path: path(to: :manifests))
  end

  def path(from: nil, to: nil, absolute: false)
    project_path.path(from: from, to: to, absolute: absolute)
  end

  def project_path
    @project_path ||= ProjectPath.new(paths: CnfsCli.configuration.paths, context_attrs: context_attrs)
  end

  # Used by runtime generators for templates by runtime to query services
  def labels
    @labels ||= (
      c_hash = components.each_with_object({}) {|c, h| h[c.c_name] = c.name }
      { 'context' => context_name }.merge(c_hash)
    )
  end

  def context_name
    @context_name ||= context_attrs.join('_')
  end

  def context_attrs
    @context_attrs ||= components.order(:id).pluck(:name)
  end

  class << self
    def create_table(schema)
      schema.create_table table_name, force: true do |t|
        t.references :root
        # t.references :component
        t.string :options
        t.string :args
      end
    end

    def after_node_load
      # obj = Project.first.context
      # binding.pry
      # obj = create(root: Project.first)
      # Project.first.update(context: obj, c_name: 'project', skip_node_create: true)
    end
  end
end
