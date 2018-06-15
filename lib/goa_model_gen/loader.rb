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
        if d[fields_key]
          d[fields_key].each do |fname, f|
            t.fields << build_field(fname, f)
          end
        end
      end
    end

    def build_field(name, f)
      Field.new(name, f)
    end

    def dig(path)
      dig_into(raw, path.split('/'), [])
    end

    def dig_into(hash, keys, footprints)
      puts "dig_into(hash, #{keys.inspect}, #{footprints.inspect})"
      key = keys.shift
      value = hash[key]
      return value if keys.empty?
      raise "No data for #{key} in #{footprint.join('/')}" if value.nil?
      return dig_into(value, keys, footprints + [key])
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
      super(path, SwaggerDef, 'definitions', 'properties')
    end

    def build_type(name, d)
      super(name, d).tap do |r|
        required_fields = d['required']
        r.fields.each do |f|
          f.required = required_fields.include?(f.name)
        end
      end
    end

    def load(name)
      d = raw[types_key][name]
      raise "#{name} not found in #{path}" unless d
      build_type(name, d)
    end
  end
end
