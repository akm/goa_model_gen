require "goa_model_gen"

require "erb"
require "pathname"

require "thor"

require "goa_model_gen/loader"
require "goa_model_gen/generator"

module GoaModelGen
  class Cli < Thor
    class << self
      def default_go_package!
        gopath = ENV['GOPATH'] || ''
        raise "$GOPATH not found" if gopath.empty?
        return Pathname.new(Dir.pwd).relative_path_from(Pathname.new(File.join(gopath, "src"))).to_s
      end

      def default_go_package
        return default_go_package!
      rescue
        nil
      end
    end

    class_option :go_package, type: :string, default: default_go_package, desc: 'Base go package name'
    class_option :swagger_yaml, type: :string, default: './swagger/swagger.yaml', desc: 'Swagger definition YAML file'

    desc "show FILE1...", "Show model info from definition files"
    def show(*paths)
      load_types_for(paths, options[:swagger_yaml]) do |path, types|
        puts "types in #{path}"
        puts YAML.dump(types)
      end
    end

    desc "model FILE1...", "Generate model files from definition files"
    option :dir, type: :string, default: './model', desc: 'Output directory path'
    option :gofmt, type: :boolean, default: true, desc: 'Run gofmt for generated file'
    def model(*paths)
      generator = new_generator('templates/model.go.erb')
      load_types_for(paths, options[:swagger_yaml]) do |path, types|
        dest = File.join(options[:dir], File.basename(path, ".*") + ".go")
        generator.run(types, dest)
        if options[:gofmt]
          system("gofmt -w #{dest}")
        end
      end
    end

    desc "converter FILE1...", "Generate converter files from definition files and swagger.yaml"
    option :package, type: :string, default: 'controller', desc: 'package name'
    option :dir, type: :string, default: './controller', desc: 'Output directory path'
    option :gofmt, type: :boolean, default: true, desc: 'Run gofmt for generated file'
    def converter(*paths)
      generator = new_generator('templates/converter.go.erb')
      load_types_for(paths, options[:swagger_yaml]) do |path, types|
        dest = File.join(options[:dir], File.basename(path, ".*") + "_conv.go")
        if types.any?{|t| !!t.payload || !!t.media_type}
          generator.run(types, dest)
          if options[:gofmt]
            system("gofmt -w #{dest}")
          end
        end
      end
    end

    no_commands do
      def new_generator(rel_path)
        opts = {
          go_package: options[:go_package],
        }
        GoaModelGen::Generator.new(File.expand_path('../' + rel_path, __FILE__), opts)
      end


      def load_types_for(paths, swagger_yaml)
        swagger_loader = GoaModelGen::SwaggerLoader.new(swagger_yaml)
        path_to_types = {}
        defined_types = {}
        paths.each do |path|
          types = GoaModelGen::ModelLoader.new(path).load_types
          types.each{|t| t.assign_swagger_types(swagger_loader) }
          types.each{|t| defined_types[t.name] = t }
          path_to_types[path] = types
        end
        paths.each do |path|
          types = path_to_types[path]
          types.each{|t| t.assign_field_type_base(defined_types) }
        end
        paths.each do |path|
          yield(path, path_to_types[path])
        end
      end

    end

  end
end
