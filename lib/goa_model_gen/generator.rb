require "goa_model_gen"

require "erb"

## Used in templates
require "active_support/core_ext/string"

module GoaModelGen
  class Generator
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def run(rel_path, types, path)
      abs_path = File.expand_path('../' + rel_path, __FILE__)
      erb = ERB.new(File.read(abs_path), nil, "-")
      erb.filename = abs_path
      content = erb.result(binding)
      open(path, 'w'){|f| f.puts(content) }
    end

  end
end
