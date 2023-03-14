# frozen_string_literal: true

module Typeaway
  class << self
    def extensions() = SolidSupport.extensions
  end

  class Extension < SolidSupport::Extension
    def self.gem_root() = Plugin.gem_root
  end
end