# coding: utf-8
require 'goa_model_gen'
require 'goa_model_gen/type'

require "active_support/core_ext/string"

module GoaModelGen
  class SourceFile
    attr_reader :yaml_path, :types
    def initialize(yaml_path, types)
      @yaml_path, @types = yaml_path, types
    end

    def model_dependencies
      @model_dependencies ||= calc_model_dependencies
    end

    def calc_model_dependencies
      r = []
      r << "github.com/goadesign/goa/uuid" if types.any?(&:use_uuid?)
      if types.any?(&:store?)
        r << "fmt"
        r << "golang.org/x/net/context"
        r << "google.golang.org/appengine/datastore"
        r << "google.golang.org/appengine/log"
      end
      r << "time" if types.any?(&:has_time_field?)
      r.uniq
    end
  end
end
