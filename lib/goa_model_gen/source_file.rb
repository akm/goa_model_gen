# coding: utf-8
require 'goa_model_gen'
require 'goa_model_gen/type'

module GoaModelGen
  class SourceFile
    attr_reader :yaml_path, :types
    def initialize(yaml_path, types)
      @yaml_path, @types = yaml_path, types
    end

    def basename
      File.basename(yaml_path, ".*")
    end
  end
end
