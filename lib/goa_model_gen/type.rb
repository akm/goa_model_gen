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

    def assign_field_type_base(types)
      self.fields.each{|f| f.assign_type_base(types) }
    end
  end

  class Model < Type
    attr_reader :enum_items, :enum_path
    attr_reader :payload, :media_type
    attr_reader :payload_name, :media_type_name
    attr_reader :goon
    attr_reader :base

    def initialize(name, attrs)
      super(name, attrs)
      @base = attrs['base']
      @enum_path = attrs['enum']
      @goon = attrs['goon']
      @payload_name = check_blank(attrs['payload']){ store? ? "#{@name}Payload" : @name }
      @media_type_name = check_blank(attrs['media_type']){ @name }
    end

    def check_blank(s)
      s.nil? ? (block_given? ? yield : nil) :
        (s.empty? || s == '-') ? nil : s
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
      $stderr.puts "assign_swagger_types for #{name.inspect}"
      # Original Type: VmDisk
      # Swagger type : VmDisk
      # Goa struct   : VMDisk
      # Goa struct name is a little different from others.
      # Use underscore and camelize to regularize it.
      if !fields.empty?
        @payload = loader.load(to_swagger_name(payload_name)) if payload_name
        @media_type = loader.load(media_type_name) if media_type_name
      elsif enum_path
        @enum_items = loader.dig(enum_path)
      end
    end

    def to_swagger_name(name)
      name.split('-').map{|n| n.underscore.camelize }.join('-')
    end

    def media_type_name_for_go
      Goa.capitalize_join(media_type_name.split('-').map(&:underscore).map{|n| n.split('_')}.flatten)
    end
  end

  class SwaggerDef < Type
  end
end
