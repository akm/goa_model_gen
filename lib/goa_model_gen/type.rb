require "goa_model_gen"

module GoaModelGen
  class Type
    attr_reader :name, :fields

    def initialize(name, attrs)
      @name = name
      @fields = []
    end

    def field_diffs(names)
      self.fields.reject{|f| names.include?(f.name) }
    end
  end

  class Model < Type
    attr_reader :payload, :media_type
    attr_reader :payload_name, :media_type_name
    attr_reader :goon

    def initialize(name, attrs)
      super(name, attrs)
      @goon = attrs['goon']
      @payload_name = attrs['payload'] || (store? ? "#{@name}Payload" : @name)
      @media_type_name = attrs['media_type'] || @name
    end

    def id_type
      if goon && goon['id'] == 'UUID'
        return 'string'
      else
        goon && goon['id']
      end
    end

    def store?
      !!goon
    end

    def assign_swagger_types(loader)
      # Original Type: VmDisk
      # Swagger type : VmDisk
      # Goa struct   : VMDisk
      # Goa struct name is a little different from others.
      # Use underscore and camelize to regularize it.
      @payload = loader.load(to_swagger_name(payload_name))
      @media_type = loader.load(to_swagger_name(media_type_name))
    end

    def to_swagger_name(name)
      name.split('-').map{|n| n.underscore.camelize }.join('-')
    end

    def media_type_name_for_go
      media_type_name.gsub('-', '')
    end
  end

  class SwaggerDef < Type
  end
end
