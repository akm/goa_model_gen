require "goa_model_gen"

module GoaModelGen
  class Type
    attr_reader :name, :fields
    attr_reader :payload, :media_type
    attr_reader :goon

    def initialize(name, attrs)
      @name = name
      @fields = []
      @payload = attrs['payload'] || "#{@name}Payload"
      @media_type = attrs['media_type'] || @name
      @goon = attrs['goon']
    end

    def id_type
      if goon && goon['id'] == 'UUID'
        return 'string'
      else
        goon && goon['id']
      end
    end

    def model?
      !!goon
    end
  end
end
