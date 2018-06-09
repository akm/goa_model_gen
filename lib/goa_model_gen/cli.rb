require "goa_model_gen"

require "thor"

require "goa_model_gen/loader"

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
    end

  end
end
