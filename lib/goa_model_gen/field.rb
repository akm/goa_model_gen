# coding: utf-8
require 'goa_model_gen'
require 'goa_model_gen/goa'

require "active_support/core_ext/string"

module GoaModelGen
  class Field
    attr_reader :name, :type, :default
    attr_accessor :format # for swagger. See https://swagger.io/docs/specification/data-models/data-types/
    attr_accessor :required
    attr_accessor :unique
    attr_accessor :validation
    attr_accessor :swagger_name
    attr_reader :type_obj
    attr_reader :datastore_tag

    def initialize(name, attrs)
      @name = name
      @type = attrs['type']
      @format = attrs['format']
      @required = attrs['required']
      @unique = attrs['unique']
      @default = attrs['default']
      @validation = attrs['validation']
      @goa_name = attrs['goa_name']
      @swagger_name = attrs['swagger_name']
      @datastore_tag = attrs['datastore_tag']
    end

    # https://goa.design/design/overview/
    PRIMITIVE_TYPES = %w[bool int int64 float string time.Time uuid.UUID *datastore.Key]

    def goa_name
      @goa_name.presence || Goa.capitalize_join(swagger_name.split("_"))
    end

    def swagger_name
      @swagger_name.presence ||name.underscore
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

    def unique?
      !!unique
    end

    def not_null?
      required || !default.nil?
    end
    def nullable?
      !not_null?
    end

    def zero_value_expression
      case type
      when 'bool' then 'false'
      when 'int', 'int32', 'int64',
           'float', 'float32', 'float64' then '0'
      when 'string', 'UUID' then '""'
      else raise "Unsupproted zero value for #{type}"
      end
    end

    def assign_type_base(types)
      @type_obj = types[self.type]
    end

    def tag
      json_tag = name.underscore.dup
      json_tag << ',omitempty' if nullable?
      validate_tags = nullable? ? [] : ['required']
      validate_tags << validation.presence
      validate_tags.compact!
      [
        ['json', json_tag],
        ['validate', validate_tags.join(',').presence],
        ['datastore', datastore_tag],
      ].map{|k,v| v ? "#{k}:\"#{v}\"" : nil}.compact.join(' ')
    end

    def definition
      "#{ name } #{ type } `#{ tag }`"
    end

    def type_package
      type.include?('.') ? type.split('.', 2).first.sub(/\A\*/, '') : nil
    end

    # https://swagger.io/docs/specification/data-models/data-types/
    # https://tour.golang.org/basics/11
    # https://golang.org/pkg/go/types/#pkg-variables
    SWAGGER_TYPE_TO_GOLANG_TYPE = {
      "string" => Hash.new("string"),
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

    MODEL_FUNC_NAME_FILTERS = {
      "TimeTime" => "Time",
    }

    def conv_func_part_for_model
      r = conv_func_part_for(type, !!(/\A\*/ =~ type))
      MODEL_FUNC_NAME_FILTERS[r] || r
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
        if type_obj && type_obj.base
          if f.not_null?
            return false, false, type # 型キャスト
          else
            st = f.golang_type.camelize
            dt = type_obj.base.camelize
            return false, false, ["#{st}PointerTo#{dt}", type] # ポインタを値にしてから型キャスト
          end
        else
          return false, true, "#{type}PayloadToModel"
        end
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

    def media_type_assignment_options(f)
      if custom?
        if type_obj && type_obj.base
          if f.not_null?
            return false, false, type_obj.base # 型キャスト
          else
            st = type_obj.base.camelize
            dt = f.golang_type.camelize
            return false, false, [type_obj.base, "#{st}To#{dt}Pointer"] # 型キャストしてポインタを値に変換
          end
        else
          return false, true, "#{type}ModelToMediaType"
        end
      else
        if type == f.golang_type
          if f.not_null?
            return true, nil, nil
          else
            return false, false, "#{conv_func_part_for_model}To#{f.conv_func_part_for_payload}"
          end
        else
          with_error = (type == 'string')
          return false, with_error, "#{conv_func_part_for_model}To#{f.conv_func_part_for_payload}"
        end
      end
    end

  end
end
