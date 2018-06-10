require "goa_model_gen"

require "erb"

require "thor"

require "goa_model_gen/loader"
require "goa_model_gen/generator"

module GoaModelGen
  class Cli < Thor

    desc "show FILE1...", "Show model info from definition files"
    def show(*paths)
      model_def_loader = GoaModelGen::ModelLoader.new
      paths.each do |path|
        types = model_def_loader.load(path)
        puts "types in #{path}"
        puts YAML.dump(types)
      end
    end

    desc "model FILE1...", "Generate model files from definition files"
    option :dir, type: :string, default: './model', desc: 'Output directory path'
    option :gofmt, type: :boolean, default: true, desc: 'Run gofmt for generated file'
    def model(*paths)
      generator = GoaModelGen::Generator.new(File.expand_path('../templates/model.go.erb', __FILE__))
      model_def_loader = GoaModelGen::ModelLoader.new
      paths.each do |path|
        types = model_def_loader.load(path)
        dest = File.join(options[:dir], File.basename(path, ".*") + ".go")
        generator.run(types, dest)
        if options[:gofmt]
          system("gofmt -w #{dest}")
        end
      end
    end

  end
end
