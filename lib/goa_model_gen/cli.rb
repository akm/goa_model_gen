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
        types = GoaModelGen::Loader.load(path)
        puts "types in #{path}"
        puts YAML.dump(types)
      end
    end

    desc "model FILE1...", "Generate model files from definition files"
    option :dir, type: :string, default: './model', desc: 'Output directory path'
    def model(*paths)
      generator = GoaModelGen::Generator.new(File.expand_path('../templates/model.go.erb', __FILE__))
      paths.each do |path|
        types = GoaModelGen::Loader.load(path)
        dest = File.join(options[:dir], File.basename(path, ".*") + ".go")
        generator.run(types, dest)
      end
    end

  end
end
