# frozen_string_literal: true

class User < ApplicationRecord
  include Concerns::Asset
  include Concerns::Taggable

  def as_save
    attributes.except('id')
  end

  class << self
    def add_columns(t)
      t.string :role
      t.string :full_name
      t.string :tags
    end
  end
end
