require "goa_model_gen"

require "erb"

## Used in templates
require "active_support/core_ext/string"

module GoaModelGen
  class Generator
    # These are used in templates
    attr_reader :config
    attr_accessor :source_file

    def initialize(config)
      @config = config
    end

    def generate(template_path)
      abs_path = File.expand_path('../' + template_path, __FILE__)
      erb = ERB.new(File.read(abs_path), nil, "-")
      erb.filename = abs_path
      content = erb.result(binding)
    end

    def run(template_path, output_path, overwrite: false)
      return if File.exist?(output_path) && !overwrite
      content = generate(template_path)
      open(output_path, 'w'){|f| f.puts(content) }
      if (File.extname(output_path) == '.go') && !config.gofmt_disabled
        system("gofmt -w #{output_path}")
      end
    end

  end
end
