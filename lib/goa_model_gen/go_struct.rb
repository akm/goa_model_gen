# coding: utf-8
require 'goa_model_gen'

require "active_support/core_ext/string"

module GoaModelGen
  class GoStruct
    attr_reader :name, :pkg_path, :size, :fields
    def initialize(d)
      @name = d['Name']
      @pkg_path = d['PkgPath']
      @size = d['Size']
      @fields = (d['Fields'] || []).map do |f|
        GoStructField.new(f)
      end
    end
  end

  class GoStructField
    attr_reader :name, :type, :anonymous, :tags
    def initialize(d)
      @name = d['Name']
      @anonymous = d['Anonymous']
      @type = GoStructFieldType.new(d['Type'])
      @tags = d['Tag'] || {}
    end
  end

  class GoStructFieldType
    attr_reader :name, :kinds, :pkg_path, :representation
    def initialize(d)
      @name = d['Name']
      @kinds = d['Kinds']
      @pkg_path = d['PkgPath']
      @representation = d['Representation']
    end

    def ==(other)
      (pkg_path == other.pkg_path) &&
        (name == other.name) &&
        (kinds == other.kinds) &&
        (representation == other.representation)
    end
    alias_method :assignable_with?, :==

    def pointer?
      kinds.last == 'ptr'
    end
    def pointer_of?(other)
      (pkg_path == other.pkg_path) &&
        (name == other.name) &&
        (kinds == (other.kinds + ['ptr']))
    end
    def pointee_of?(other)
      other.pointer_of?(self)
    end

    def needs_error_to_convert_to?(other)
      return false if other.name == 'string'
      return true if name == 'string'
      return false
    end

    def method_part_name
      parts = kinds.dup
      parts.pop if parts.last == 'ptr'
      parts =
        (parts.first == 'struct' || pkg_path.present?) ?
          [name] + parts[1..-1] : parts
      parts.map(&:camelize).join
    end
  end
end
