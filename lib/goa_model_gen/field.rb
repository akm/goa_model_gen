require 'goa_model_gen'

module GoaModelGen
  class Field
    attr_reader :name, :type, :default
    attr_accessor :required

    def initialize(name, attrs)
      @name = name
      @type = attrs['type']
      @required = attrs['required']
      @default = attrs['default']
    end

    # https://goa.design/design/overview/
    PRIMITIVE_TYPES = %q[bool int float string time.Time uuid.UUID interface{}]

    def primitive?
      PRIMITIVE_TYPES.include?(type)
    end

    def custom?
      !primitive?
    end

    def optional?
      !required
    end
  end
end
