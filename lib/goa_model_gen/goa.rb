require 'goa_model_gen'

module GoaModelGen
  module Goa
    module_function

    SPECIAL_NAMES = {
      "id" => "ID",
      "vm" => "VM",
    }

    def capitalize_join(names, separator = nil)
      names.map{|s| SPECIAL_NAMES[s] || s.capitalize}.join(separator)
    end

  end
end
