require "goa_model_gen"

require "thor"

module GoaModelGen
  class Cli < Thor

    desc "model FILE1...", "Generate model files from definition files"
    option :dir, type: :string, default: './model', desc: 'Output directory path'
    def model(*paths)
      puts "paths: #{paths.inspect}"
    end

  end
end
