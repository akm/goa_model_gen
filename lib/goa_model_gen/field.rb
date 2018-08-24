require 'goa_model_gen'
require 'goa_model_gen/goa'

require "active_support/core_ext/string"

module GoaModelGen
  class Field
    attr_reader :name, :type, :default
    attr_accessor :format # for swagger. See https://swagger.io/docs/specification/data-models/data-types/
    attr_accessor :required
    attr_reader :type_obj
    attr_reader :datastore_tag

    def initialize(name, attrs)
      @name = name
      @type = attrs['type']
      @format = attrs['format']
      @required = attrs['required']
      @default = attrs['default']
      @datastore_tag = attrs['datastore_tag']
    end

    # https://goa.design/design/overview/
    PRIMITIVE_TYPES = %w[bool int int64 float string time.Time uuid.UUID *datastore.Key]

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

    # https://swagger.io/docs/specification/data-models/data-types/
    # https://tour.golang.org/basics/11
    # https://golang.org/pkg/go/types/#pkg-variables
    SWAGGER_TYPE_TO_GOLANG_TYPE = {
      "string" => Hash.new("string").update(
        "date" => "time.Time",
        "date-time" => "time.Time",
      ),
      "number" => Hash.new("float32").update(
        "double" => "float64",
      ),
      "integer" => Hash.new("int"),
      "boolean" => Hash.new("bool"),
    }

    def golang_type
      format2type = SWAGGER_TYPE_TO_GOLANG_TYPE[type]
      raise "Golang type not found for #{self.inspect}" unless format2type
      return format2type[format]
    end

    def conv_func_part_for_model
      conv_func_part_for(type, !!(/\A\*/ =~ type))
    end

    def conv_func_part_for_payload
      conv_func_part_for(golang_type, nullable?)
    end

    def conv_func_part_for_media_type
      conv_func_part_for(golang_type, nullable?)
    end

    def conv_func_part_for(value, with_pointer)
      r = value.sub(/\A\*/, '').split('.').map(&:camelize).join
      with_pointer ? "#{r}Pointer" : r
    end

    def payload_assignment_options(f)
      if custom?
        return false, true, "#{type}PayloadToModel"
      else
        if type == f.golang_type
          if f.not_null?
            return true, nil, nil
          else
            return false, false, "#{f.conv_func_part_for_payload}To#{conv_func_part_for_model}"
          end
        else
          with_error = (f.type == 'string')
          return false, with_error, "#{f.conv_func_part_for_payload}To#{conv_func_part_for_model}"
        end
      end
    end

  end
end
