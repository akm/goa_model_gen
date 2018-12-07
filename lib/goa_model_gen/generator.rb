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

    def generate(template_path)
      clear_dependencies

      abs_path = File.expand_path('../' + template_path, __FILE__)
      erb = ERB.new(File.read(abs_path), nil, "-")
      erb.filename = abs_path
      body = erb.result(binding).strip

      raise "No package given in #{abs_path}" if package.blank?

      base = ERB.new(File.read(GO_BASE_PATH), nil, "-")
      base.filename = GO_BASE_PATH
      base.result(binding).strip << "\n"
    end

    COLORS = {
      generate: "\e[32m",        # green   # !file_exist
      no_change: "\e[37m",    # white   # file_exist && !modified
      overwrite: "\e[33m",       # yellow  # file_exist && !user_editable
      keep: "\e[34m",            # blue    # file_exist && user_editable && !force
      force_overwrite: "\e[31m", # red     # file_exist && user_editable && force
      clear: "\e[0m",            # clear
    }
    MAX_ACTION_LENGTH = COLORS.keys.map(&:to_s).map(&:length).max

    def run(template_path, output_path)
      content = generate(template_path)
      if (File.extname(output_path) == '.go') && !config.gofmt_disabled
        # https://docs.ruby-lang.org/ja/2.5.0/class/IO.html#S_POPEN
        content = IO.popen("gofmt", "r+") do |io|
          io.puts(content)
          io.close_write
          io.read
        end
      end
      if thor
        options = {skip: skip, force: force}
        thor.create_file(output_path, content, options)
      else
        already_exist = File.exist?(output_path)
        modified = already_exist ? (content != File.read(output_path)) : true
        action =
          !already_exist ? :generate :
            !modified ? :no_change :
              !user_editable? ? :overwrite :
                force ? :force_overwrite : :keep
        GoaModelGen.logger.info("%s%-#{MAX_ACTION_LENGTH}s %s%s" % [COLORS[action], action.to_s, output_path, COLORS[:clear]])
        return if action == :no_change
        return if skip
        open(output_path, 'w'){|f| f.puts(content) }
      end
    end

    def process(temp_path_to_dest_path)
      temp_path_to_dest_path.each{|src, dest| run(src, dest) }
    end
  end
end
