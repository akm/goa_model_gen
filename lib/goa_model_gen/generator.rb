require "goa_model_gen"

require "erb"

## Used in templates
require "active_support/core_ext/string"

module GoaModelGen
  class Generator
    # These are used in templates
    attr_reader :config
    attr_accessor :types

    def initialize(config)
      @config = config
    end

    def run(rel_path, path)
      abs_path = File.expand_path('../' + rel_path, __FILE__)
      erb = ERB.new(File.read(abs_path), nil, "-")
      erb.filename = abs_path
      content = erb.result(binding)
      open(path, 'w'){|f| f.puts(content) }
    end

  end
end
