# frozen_string_literal: true

module SolidRecord
  class << self
    def with_model_element_callbacks
      model_element_callbacks.each { |cb| ModelElement.set_callback(*cb) }
      ret_val = yield
    rescue StandardError => e
      SolidRecord.raise_or_warn(e)
    ensure
      model_element_callbacks.each { |cb| ModelElement.skip_callback(*cb) }
      ret_val
    end

    def model_element_callbacks() = [%i[create before create_model], %i[create after create_associations]]
  end

  class ModelSaveError < Error; end

  class ModelElement < Element
    # TODO: Note where each of these attributes originate from
    # The ID used to reference the model
    attr_accessor :key

    # The model instance of model_class that is created from this element
    belongs_to :model, polymorphic: true

    delegate :key_column, to: :model_class

    # NOTE: These callbacks are enabled/disabled by SolidRecord.with_model_element_callbacks block
    # They are listed here only for reference
    # before_create :create_model
    # after_create :create_associations

    # The created model's string key in the table's user defined 'key_column'
    def model_key() = model.send(key_column)

    # Create an instance of model_class and assign it to the model attribute
    def create_model
      self.model = model_class.create(model_values)
      raise ModelSaveError, "Err #{model_class}: #{model.errors.full_messages.join('. ')}" unless model.persisted?
    rescue ModelSaveError, ActiveModel::UnknownAttributeError, ActiveRecord::SubclassNotFound => e
      binding.pry
      SolidRecord.raise_or_warn(e, "#{model_class} #{e.message} Check values for:\n#{config_values}")
    end

    def config_values
      "SolidRecord.config.namespace: #{SolidRecord.config.namespace}\n" \
        "#{model_class}.owner_association_name: #{model_class.owner_association_name}\n" \
        "#{model_class}.key_column: #{model_class.key_column}" \
    end

    # @return [Hash] Merge the original values with owner and any belongs_to calculated IDs
    def model_values
      values.except(*assn_names).merge(belongs_to_attributes).merge(owner_attribute).merge(key_column => key)
    end

    def owner_attribute
      # def owner_attribute() = owner ? { owner.class.base_class.name.downcase => owner } : {}
      return {} if owner.nil?
      return { model_class.owner_association_name => owner } if model_class.owner_association_name
      if (bt = model_class.reflect_on_all_associations(:belongs_to)).size.eql?(1)
        return { bt.first.name => owner }
      end
      SolidRecord.raise_or_warn(StandardError.new('no owner found'))
      {}
    end

    # def owner_attribute
    #   # abstract_class returns true if the class is abstract and nil if not
    #   is_sti = owner.nil? ? false : owner.class.superclass.abstract_class.nil?
    #   owner ? { 'owner' => owner } : {}
    #   ret_val = owner ? { model_class.owner_association_name => owner } : {}
    #   binding.pry if owner
    #   ret_val
    # end

    # For each belongs_to association on the model_class
    # @return [Hash] of model_foreign_key_column => identified foreign key value
    def belongs_to_attributes
      model_class.reflect_on_all_associations(:belongs_to).each_with_object({}) do |assn, _hash|
        fk_attribute = "#{assn.name}_#{SolidRecord.config.reference_suffix}" # user_name
        # In a monolithic document the foreign key value is not part of the document hierarchy so it will be nil
        next unless (fk_value = values[fk_attribute])

        # model_fk = assn.options[:foreign_key] || "#{assn.name}_id"
        # TODO: Maybe check and raise if not model_class.column_names.include?(model_fk)
        # binding.pry
        # raise 'TODO: This will be a bug'
        # assn_id = root.identify(key: fk_value, type: assn.name.to_s.pluralize)
        # hash[model_fk] = assn_id
      end
    end

    # If this element's payload includes associations then create elements for those
    def create_associations
      assn_names.each do |assn_name|
        next unless (assn_values = values[assn_name])

        elements.create(type: 'SolidRecord::Association', name: assn_name,
                        model_type: assn_name.classify, values: assn_values, owner: model)
      end
    end

    def assn_names() = model_class.reflect_on_all_associations(:has_many).map { |a| a.name.to_s }

    # The Persistence Concern adds lifecycle methods to the model's callback chains
    # When a model's lifecycle event is triggred it invokes its element's method of the same name
    def __update_element() = document.flag(:update)

    def __destroy_element
      update(flags: flags << :destroy)
      document.flag(:update)
    end

    def to_solid_hash() = { model_key => to_solid.except(key_column) }

    def to_solid() = solid_elements.each_with_object(as_solid) { |e, hash| hash[e.name] = e.to_solid }

    def as_solid
      model.encrypt_attrs if model.respond_to?(:encrypt_attrs)
      model.as_solid.compact.sort.to_h
    end

    def solid_elements() = elements.where.not(type: 'SolidRecord::Path')

    def tree_label() = "#{model_key} (#{type.demodulize})"

    # Called from persistence#__after_create
    def add_model(new_model)
      assn = elements.find_by(model_type: new_model.class.name)
      assn.elements.create(type: 'SolidRecord::ModelElement', model: new_model, owner: model)
      document.flag(:update)
    end
  end
end