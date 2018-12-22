require "goa_model_gen"

require "thor"

require "goa_model_gen/logger"
require "goa_model_gen/config"
require "goa_model_gen/loader"
require "goa_model_gen/generator"

module GoaModelGen
  class Cli < Thor
    include Thor::Actions

    class_option :version, type: :boolean, aliases: 'v', desc: 'Show version before processing'
    class_option :skip, type: :boolean, aliases: 's', desc: "Skip generate file"
    class_option :force, type: :boolean, aliases: 'f', desc: 'Force overwrite files'
    class_option :keep_editable, type: :boolean, aliases: 'k', default: true, desc: 'Keep user editable file'
    class_option :log_level, type: :string, aliases: 'l', desc: 'Log level, one of  debug,info,warn,error,fatal. The default value is info'
    class_option :config, type: :string, aliases: 'c', default: './goa_model_gen.yaml', desc: 'Path to config file. You can generate it by config subcommand'

    desc "config", "Generate config file"
    def config(path = './goa_model_gen.yaml')
      setup
      open(path, 'w'){|f| f.puts(Config.new.fulfill.to_yaml) }
    end

    desc "show FILE1...", "Show model info from definition files"
    def show(*paths)
      setup
      load_types_for(paths) do |source_file|
        puts "types in #{source_file.yaml_path}"
        puts YAML.dump(source_file.types)
      end
    end

    desc "model FILE1...", "Generate model files from definition files"
    def model(*paths)
      setup
      new_generator.process({
        "templates/goon.go.erb" => File.join(cfg.model_dir, "goon.go"),
        'templates/validator.go.erb' => File.join(cfg.model_dir, 'validator.go'),
      })
      load_types_for(paths) do |source_file|
        new_generator.tap{|g| g.source_file = source_file }.process({
          'templates/model.go.erb' => File.join(cfg.model_dir, "#{source_file.basename}.go"),
          'templates/model_store.go.erb' => File.join(cfg.model_dir, "#{source_file.basename}_store.go"),
          'templates/model_validation.go.erb' => File.join(cfg.model_dir, "#{source_file.basename}_validation.go"),
        })
      end
    end

    desc "converter FILE1...", "Generate converter files from definition files and swagger.yaml"
    def converter(*paths)
      setup
      new_generator.process({
        "templates/converter_base.go.erb" => File.join(cfg.controller_dir, "converter_base.go"),
      })
      load_types_for(paths) do |source_file|
        next if source_file.types.all?{|t| !t.payload && !t.media_type}
        new_generator.tap{|g| g.source_file = source_file }.process({
          'templates/converter.go.erb' => File.join(cfg.controller_dir, "#{source_file.basename}_conv.go"),
        })
      end
    end

    desc "version", "Show version"
    def version
      show_version
    end

    no_commands do
      def setup
        show_version if options[:version]
        GoaModelGen::Logger.setup(options[:log_level] || 'info')
      end

      def show_version
        puts "#{$PROGRAM_NAME} version:#{::GoaModelGen::VERSION}"
      end

      def cfg
        @cfg ||= GoaModelGen::Config.new.load_from(options[:config])
      end

      def new_generator
        GoaModelGen::Generator.new(cfg).tap do |g|
          g.thor = self
          g.force = options[:force]
          g.skip = options[:skip]
          g.keep_editable = options[:keep_editable]
        end
      end

      def load_types_for(paths)
        loader = GoaModelGen::Loader.new(cfg)
        source_files = loader.load_files(paths)
        source_files.each do |source_file|
          yield(source_file)
        end
      end
    end

  end
end
