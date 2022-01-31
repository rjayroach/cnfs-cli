# frozen_string_literal: true

module Hendrix
  class ApplicationGenerator < Thor::Group
    include Thor::Actions
    # include Extendable

    private

    # NOTE: These methods are available within templates as well as any sub classes

    # Utility method if template is in the standard directory and the destiation file is file_name - .erb
    def cnfs_template(file_name)
      generated_files << template(templates_path.join("#{file_name}.erb"), file_name)
    end

    # Array of ERB templates in the views_path/templates directory
    def templates() = templates_path.glob('**/*.erb', File::FNM_DOTMATCH)

    def templates_path() = views_path.join('templates')

    def files() = files_path.glob('**/*', File::FNM_DOTMATCH)

    def files_path() = views_path.join('files')

    # Thor serach paths is an array. The default is a one element array based on the generator's directory
    def source_paths() = [views_path]

    def views_path() = @views_path ||= internal_path.join(assets_path)

    # returns 'runtime', 'provisioner', 'project', 'plugin', 'component', etc
    def assets_path() = self.class.name.demodulize.delete_suffix('Generator').underscore

    # The path to the currently invoked generator subclass
    def internal_path() = raise(NotImplementedError, 'Generator must implement #internal_path() = Pathname.new(__dir__)')

    # returns 'compose', 'skaffold', 'terraform', 'new', etc
    def generator_type() = self.class.name.deconstantize.underscore

    # Utility methods for managing files in the target directory

    # Use Thor's remove_file to output the removed files
    # After the generator has completed it may call this method to remove old files
    # In order to do this it must track files as they are generated by implementing:
    #
    #   generated_files << template('templates/env.erb', file_name, env: environment)
    #
    def remove_stale_files() = stale_files.each { |file| remove_file(file) }

    def stale_files() = all_files - excluded_files - generated_files

    # All files in the current directory
    def all_files() = path.glob('**/*', File::FNM_DOTMATCH).select(&:file?).map(&:to_s)

    # Array of file names that should not be removed
    # A subclass can override this method to define files that should not be considered as stale and removed
    def excluded_files() = []

    # Stores an array of files that are created during an invocation of the Generator
    def generated_files() = @generated_files ||= []

    def path() = Pathname.new('.')
  end
end
