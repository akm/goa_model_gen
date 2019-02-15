require "goa_model_gen"

require "erb"
require "yaml"
require "pathname"

require "active_support/core_ext/string"

module GoaModelGen
  class Config

    ATTRIBUTES = %w[
      go_package
      swagger_yaml
      gofmt_disabled
      model_dir
      store_dir
      converter_dir
      structs_gen_dir
      validator_path
      generator_version_comment
    ].freeze

    attr_accessor *ATTRIBUTES

    def fulfill
      @go_package     ||= default_go_package
      # @swagger_yaml   ||= "./swagger/swagger.yaml"
      @gofmt_disabled ||= false
      @model_dir      ||= "./model"
      @store_dir      ||= "./stores"
      @converter_dir  ||= "./converters"
      @structs_gen_dir ||= "./cmd/structs"
      @validator_path ||= "gopkg.in/go-playground/validator.v9"
      @generator_version_comment ||= false
      self
    end

    def load_from(path)
      erb = ERB.new(File.read(path), nil, "-")
      erb.filename = path
      config = YAML.load(erb.result, path)

      ATTRIBUTES.each do |name|
        instance_variable_set("@#{name}", config[name].presence)
      end

      fulfill
    end

    def to_hash
      ATTRIBUTES.each_with_object({}) do |name, d|
        d[name] = send(name)
      end
    end

    def to_yaml
      YAML.dump(to_hash)
    end

    def default_go_package
      return default_go_package!
    rescue
      nil
    end

    def default_go_package!
      gopath = ENV['GOPATH'] || ''
      raise "$GOPATH not found" if gopath.empty?
      return Pathname.new(Dir.pwd).relative_path_from(Pathname.new(File.join(gopath, "src"))).to_s
    end

  end
end
