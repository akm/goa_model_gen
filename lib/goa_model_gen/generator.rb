require "goa_model_gen"

require "erb"

## Used in templates
require "active_support/core_ext/string"

module GoaModelGen
  class Generator
    attr_reader :go_package

    def initialize(template_path, options = {})
      @erb = ERB.new(File.read(template_path), nil, "-")
      @erb.filename = template_path
      @go_package = options[:go_package]
    end

    def run(types, path)
      content = @erb.result(binding)
      open(path, 'w'){|f| f.puts(content) }
    end

  end
end
