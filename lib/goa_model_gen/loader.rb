require "goa_model_gen"

require "yaml"

require "goa_model_gen/type"
require "goa_model_gen/field"

module GoaModelGen
  class BaseLoader
    attr_reader :kind, :types_key, :fields_key
    def initialize(kind, types_key, fields_key)
      @kind = kind
      @types_key, @fields_key = types_key, fields_key
    end

    def load(path)
      raw = YAML.load_file(path)
      raw[types_key].map do |name, definition|
        build_type(name, definition)
      end
    end

    def build_type(name, d)
      Type.new(kind, name, d).tap do |t|
        d[fields_key].each do |fname, f|
          t.fields << build_field(fname, f)
        end
      end
    end

    def build_field(name, f)
      Field.new(name, f)
    end
  end

  class ModelDefLoader < BaseLoader
    def initialize
      super(:model, 'types', 'fields')
    end

    def build_field(name, f)
      fd = f.is_a?(Hash) ? f : {'type' => f.to_s}
      fd['type'] ||= 'string'
      super(name, fd)
    end
  end
end
