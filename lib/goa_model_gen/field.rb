require 'goa_model_gen'
require 'goa_model_gen/goa'

require "active_support/core_ext/string"

module GoaModelGen
  class Field
    attr_reader :name, :type, :default
    attr_accessor :required
    attr_reader :type_obj
    attr_reader :datastore_tag

    def initialize(name, attrs)
      @name = name
      @type = attrs['type']
      @required = attrs['required']
      @default = attrs['default']
      @datastore_tag = attrs['datastore_tag']
    end

    # https://goa.design/design/overview/
    PRIMITIVE_TYPES = %q[bool int float string time.Time uuid.UUID interface{}]

    def goa_name
      Goa.capitalize_join(name.split("_"))
    end

    def primitive?
      PRIMITIVE_TYPES.include?(type)
    end

    def custom?
      !primitive?
    end

    def optional?
      !required
    end

    def not_null?
      required || !default.nil?
    end
    def nullable?
      !not_null?
    end

    def assign_type_base(types)
      @type_obj = types[self.type]
    end

    def tag
      json_tag = name.underscore.dup
      json_tag << ',omitempty' if nullable?
      validate_tag = 'required' unless nullable?
      [
        ['json', json_tag],
        ['validate', validate_tag],
        ['datastore', datastore_tag],
      ].map{|k,v| v ? "#{k}:\"#{v}\"" : nil}.compact.join(' ')
    end
  end
end
