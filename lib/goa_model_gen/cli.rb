require "goa_model_gen"

require "erb"

require "thor"

require "goa_model_gen/loader"
require "goa_model_gen/generator"

module GoaModelGen
  class Cli < Thor

    desc "show FILE1...", "Show model info from definition files"
    def show(*paths)
      paths.each do |path|
        types = GoaModelGen::ModelLoader.new(path).load_types
        puts "types in #{path}"
        puts YAML.dump(types)
      end
    end

    desc "model FILE1...", "Generate model files from definition files"
    option :dir, type: :string, default: './model', desc: 'Output directory path'
    option :gofmt, type: :boolean, default: true, desc: 'Run gofmt for generated file'
    def model(*paths)
      generator = GoaModelGen::Generator.new(File.expand_path('../templates/model.go.erb', __FILE__))
      paths.each do |path|
        types = GoaModelGen::ModelLoader.new(path).load_types
        dest = File.join(options[:dir], File.basename(path, ".*") + ".go")
        generator.run(types, dest)
        if options[:gofmt]
          system("gofmt -w #{dest}")
        end
      end
    end

    desc "converter FILE1...", "Generate converter files from definition files and swagger.yaml"
    option :swagger_yaml, type: :string, default: './swagger/swagger.yaml', desc: 'Swagger definition YAML file'
    option :package, type: :string, default: 'controller', desc: 'package name'
    option :dir, type: :string, default: './controller', desc: 'Output directory path'
    option :gofmt, type: :boolean, default: true, desc: 'Run gofmt for generated file'
    def converter(*paths)
      generator = GoaModelGen::Generator.new(File.expand_path('../templates/converter.go.erb', __FILE__))
      swagger_loader = GoaModelGen::PayloadLoader.new(options[:swagger_yaml])
      paths.each do |path|
        types = GoaModelGen::ModelLoader.new(path).load_types
        types.each{|t| t.assign_swagger_types(swagger_loader) }
        dest = File.join(options[:dir], File.basename(path, ".*") + "_conv.go")
        generator.run(types, dest)
        if options[:gofmt]
          system("gofmt -w #{dest}")
        end
      end
    end

  end
end
