require "goa_model_gen"

require "erb"

## Used in templates
require "active_support/core_ext/string"

module GoaModelGen
  class Generator
    def initialize(template_path)
      content = File
      @erb = ERB.new(File.read(template_path), nil, "-")
      @erb.filename = template_path
    end

    def run(types, path)
      content = @erb.result(binding)
      open(path, 'w'){|f| f.puts(content) }
    end

  end
end
