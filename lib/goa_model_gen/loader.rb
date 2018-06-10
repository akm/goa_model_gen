require "goa_model_gen"

require "yaml"

require "goa_model_gen/type"
require "goa_model_gen/field"

module GoaModelGen
  module Loader
    module_function

    def load(path)
      raw = YAML.load_file(path)
      raw['types'].map do |name, definition|
        build_type(name, definition)
      end
    end

    def build_type(name, d)
      Model.new(name, d).tap do |t|
        d['fields'].each do |fname, f|
          t.fields << build_field(fname, f)
        end
      end
    end

    def build_field(name, f)
      fd = f.is_a?(Hash) ? f : {'type' => f.to_s}
      fd['type'] ||= 'string'
      Field.new(name, fd)
    end

  end
end
