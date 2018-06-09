require 'goa_model_gen'

module GoaModelGen
  class Field
    attr_reader :name, :type, :required, :default

    def initialize(name, attrs)
      @name = name
      @type = attrs['type']
      @required = attrs['required']
      @default = attrs['default']
    end
  end
end
