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

    def run(rel_path, path, overwrite: false)
      return if File.exist?(path) && !overwrite
      abs_path = File.expand_path('../' + rel_path, __FILE__)
      erb = ERB.new(File.read(abs_path), nil, "-")
      erb.filename = abs_path
      content = erb.result(binding)
      open(path, 'w'){|f| f.puts(content) }
      if (File.extname(path) == '.go') && !config.gofmt_disabled
        system("gofmt -w #{path}")
      end
    end

  end
end
