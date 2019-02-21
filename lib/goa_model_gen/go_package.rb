require "goa_model_gen"

module GoaModelGen
  module GoPackage

    # goa allows underscore for file name
    def package_path_name
      name.underscore
    end

    # underscore isn't used for go package name
    def package
      name.downcase.gsub('_', '')
    end

  end
end
