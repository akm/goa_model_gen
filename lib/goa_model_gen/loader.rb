require "goa_model_gen"

require "yaml"

require "goa_model_gen/type"
require "goa_model_gen/field"

module GoaModelGen
  module Loader
    module_function

    def load(path)
      raw = YAML.load_file(path)
      raw['types'].each_with_object({}) do |(name, definition), d|
        d[name] = build_type(name, definition)
      end
    end

    def build_type(name, d)
      Type.new(name, d).tap do |t|
        d['fields'].each do |fname, f|
          fd = f.is_a?(Hash) ? f : {'type': f.to_s}
          t.fields << Field.new(fname, fd)
        end
      end
    end

  end
end
