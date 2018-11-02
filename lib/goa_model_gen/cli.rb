require "goa_model_gen"

require "thor"

require "goa_model_gen/config"
require "goa_model_gen/loader"
require "goa_model_gen/generator"

module GoaModelGen
  class Cli < Thor
    class_option :version, type: :boolean, aliases: 'v', desc: 'Show version before processing'
    class_option :config, type: :string, aliases: 'c', default: './goa_model_gen.yaml', desc: 'Path to config file. You can generate it by config subcommand'

    desc "config", "Generate config file"
    def config(path = './goa_model_gen.yaml')
      show_version_if_required
      open(path, 'w'){|f| f.puts(Config.new.fulfill.to_yaml) }
    end

    desc "bootstrap", "Generate files not concerned with model"
    def bootstrap
      show_version_if_required
      generator = new_generator
      {
        "templates/goon.go.erb" => "model/goon.go",
        "templates/converter_base.go.erb" => "controller/converter_base.go",
      }.each do |template, dest|
        generator.run(template, dest, overwrite: true)
      end
    end

    desc "show FILE1...", "Show model info from definition files"
    def show(*paths)
      show_version_if_required
      load_types_for(paths) do |path, types|
        puts "types in #{path}"
        puts YAML.dump(types)
      end
    end

    desc "model FILE1...", "Generate model files from definition files"
    def model(*paths)
      show_version_if_required
      load_types_for(paths) do |path, types|
        generator = new_generator.tap{|g| g.types = types }
        [
          {path: 'templates/model.go.erb', suffix: '.go', overwrite: true},
          {path: 'templates/model_validation.go.erb', suffix: '_validation.go', overwrite: false},
        ].each do |d|
          dest = File.join(cfg.model_dir, File.basename(path, ".*") + d[:suffix])
          generator.run(d[:path], dest, overwrite: d[:overwrite])
        end
      end
    end

    desc "converter FILE1...", "Generate converter files from definition files and swagger.yaml"
    def converter(*paths)
      show_version_if_required
      load_types_for(paths) do |path, types|
        generator = new_generator.tap{|g| g.types = types }
        dest = File.join(cfg.controller_dir, File.basename(path, ".*") + "_conv.go")
        if types.any?{|t| !!t.payload || !!t.media_type}
          generator.run('templates/converter.go.erb', dest, overwrite: true)
        end
      end
    end

    desc "version", "Show version"
    def version
      show_version
    end

    no_commands do
      def show_version_if_required
        show_version if options[:version]
      end

      def show_version
        puts "#{$PROGRAM_NAME} version:#{::GoaModelGen::VERSION}"
      end

      def cfg
        @cfg ||= GoaModelGen::Config.new.load_from(options[:config])
      end

      def new_generator
        GoaModelGen::Generator.new(cfg)
      end

      def load_types_for(paths)
        loader = GoaModelGen::Loader.new(cfg)
        path_to_types = loader.load(paths)
        paths.each do |path|
          yield(path, path_to_types[path])
        end
      end
    end

  end
end
