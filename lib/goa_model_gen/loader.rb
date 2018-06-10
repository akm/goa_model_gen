require "goa_model_gen"

require "yaml"

require "goa_model_gen/type"
require "goa_model_gen/field"

module GoaModelGen
  class BaseLoader
    attr_reader :path, :raw
    attr_reader :kind, :types_key, :fields_key
    def initialize(path, kind, types_key, fields_key)
      @kind = kind
      @types_key, @fields_key = types_key, fields_key
      @raw = YAML.load_file(path)
    end

    def load_types
      raw[types_key].map do |name, definition|
        build_type(name, definition)
      end
    end

    def build_type(name, d)
      kind.new(name, d).tap do |t|
        d[fields_key].each do |fname, f|
          t.fields << build_field(fname, f)
        end
      end
    end

    def build_field(name, f)
      Field.new(name, f)
    end
  end

  class ModelLoader < BaseLoader
    def initialize(path)
      super(path, Model, 'types', 'fields')
    end

    def build_field(name, f)
      fd = f.is_a?(Hash) ? f : {'type' => f.to_s}
      fd['type'] ||= 'string'
      super(name, fd)
    end
  end

  class SwaggerLoader < BaseLoader
    def initialize(path)
      super(SwaggerDef, 'definitions', 'properties')
    end

    def build_type(name, d)
      r = super(name, d)
      required_fields = d['required']
      r.fields.each do |f|
        f.required = required_fields.include?(f.name)
      end
    end

    def load(name)
      d = raw[types_key][name]
      build_type(name, d)
    end
  end
end
