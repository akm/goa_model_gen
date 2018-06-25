require 'goa_model_gen'
require 'goa_model_gen/goa'

module GoaModelGen
  class Field
    attr_reader :name, :type, :default
    attr_accessor :required
    attr_reader :type_obj

    def initialize(name, attrs)
      @name = name
      @type = attrs['type']
      @required = attrs['required']
      @default = attrs['default']
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
  end
end
