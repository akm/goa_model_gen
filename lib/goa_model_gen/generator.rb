require "goa_model_gen"
require "goa_model_gen/golang_helper"

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

    def golang_helper
      @golang_helper ||= GolangHelper.new
    end

    def package(name = nil)
      if name
        @package = name
      else
        @package
      end
    end

    def dependencies
      @dependencies ||= []
    end

    def clear_dependencies
      @dependencies = nil
    end

    def import(*packages)
      packages.each do |package|
        dependencies.push(package) unless dependencies.include?(package)
      end
    end

    GO_BASE_PATH = File.expand_path('../templates/base.go.erb', __FILE__)

    def generate(template_path)
      clear_dependencies

      abs_path = File.expand_path('../' + template_path, __FILE__)
      erb = ERB.new(File.read(abs_path), nil, "-")
      erb.filename = abs_path
      body = erb.result(binding).strip

      raise "No package given in #{abs_path}" if package.blank?

      base = ERB.new(File.read(GO_BASE_PATH), nil, "-")
      base.filename = GO_BASE_PATH
      base.result(binding).strip
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
