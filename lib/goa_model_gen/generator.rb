require "goa_model_gen"
require "goa_model_gen/golang_helper"

require "erb"

## Used in templates
require "active_support/core_ext/string"

module GoaModelGen
  class Generator
    # These are used in templates
    attr_reader :config
    attr_accessor :thor
    attr_accessor :source_file
    attr_accessor :force, :skip
    attr_accessor :keep_editable

    def initialize(config)
      @config = config
      @user_editable = false
      @force = false
      @skip = false
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
      @dependencies ||= {}
    end

    def clear_dependencies
      @dependencies = nil
    end

    def import(alias_or_package, package_or_nil = nil)
      package = package_or_nil || alias_or_package
      new_alias = package_or_nil ? alias_or_package.to_s : nil
      if dependencies.key?(package)
        old_alias = dependencies[package]
        raise "Conflict alias #{old_alias.inspect} and #{new_alias.inspect}" if old_alias != new_alias
      end
      dependencies[package] ||= new_alias
    end

    def user_editable(value: true)
      @user_editable = value
    end
    def user_editable?
      @user_editable
    end

    GO_BASE_PATH = File.expand_path('../templates/base.go.erb', __FILE__)

    PACKAGE_FOR_IMPORT = {
      "datastore" => "google.golang.org/appengine/datastore",
    }

    def generate(template_path, variables = {})
      clear_dependencies
      user_editable(value: false)

      abs_path = File.expand_path('../' + template_path, __FILE__)
      erb = ERB.new(File.read(abs_path), nil, "-")
      erb.filename = abs_path

      variables.each do |key, val|
        define_singleton_method(key){ val }
      end

      body = erb.result(binding).strip

      raise "No package given in #{abs_path}" if package.blank?

      base = ERB.new(File.read(GO_BASE_PATH), nil, "-")
      base.filename = GO_BASE_PATH
      r = base.result(binding).strip << "\n"
      r = gofmt(r) unless config.gofmt_disabled
      return r
    end

    def gofmt(content)
      # https://docs.ruby-lang.org/ja/2.5.0/class/IO.html#S_POPEN
      return IO.popen("gofmt", "r+") do |io|
        io.puts(content)
        io.close_write
        io.read
      end
    end

    COLORS = {
      blue:  "\e[34m",
      clear: "\e[0m",
    }

    def run(template_path, output_path, variables = {}, &block)
      content = generate(template_path, variables, &block)

      if user_editable? && keep_editable && File.exist?(output_path)
        $stderr.puts("%sKEEP%s %s" % [COLORS[:blue], COLORS[:clear], output_path])
        return
      end

      options = {skip: skip, force: force}
      thor.create_file(output_path, content, options)
    end

    def process(temp_path_to_dest_path)
      temp_path_to_dest_path.each{|src, dest| run(src, dest) }
    end
  end
end
