require 'goa_model_gen/field'

RSpec.describe GoaModelGen::Field do
  describe :tag do
    it :nullable do
      f = GoaModelGen::Field.new("TestField", {})
      expect(f.tag).to eq 'json:"test_field,omitempty"'
    end

    it :required do
      f = GoaModelGen::Field.new("TestField", 'required' => true)
      expect(f.tag).to eq 'json:"test_field" validate:"required"'
    end

    it :datastore_tag do
      f = GoaModelGen::Field.new("TestField", 'datastore_tag' => 'noindex')
      expect(f.tag).to eq 'json:"test_field,omitempty" datastore:"noindex"'
    end

  end
end
