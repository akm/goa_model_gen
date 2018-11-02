require 'goa_model_gen/config'
require 'goa_model_gen/loader'

RSpec.describe GoaModelGen::Type do

  let(:config) do
    GoaModelGen::Config.new.tap do |c|
      c.go_package = "github.com/akm/goa_model_gen/project1"
      c.swagger_yaml   = File.expand_path("../project1/swagger/swagger.yaml", __FILE__)
      c.gofmt_disabled = true
      c.model_dir = File.expand_path("../project1/model", __FILE__)
      c.controller_dir = File.expand_path("../project1/controller", __FILE__)
    end
  end
  let(:model_yamls){ Dir.glob(File.expand_path('../project1/design/*.yaml', __FILE__)) }

  let(:loader){ GoaModelGen::Loader.new(config) }
  let(:path_to_types){ loader.load_types(model_yamls) }
  let(:types){ path_to_types.values.flatten }

  let(:user){ types.detect{|t| t.name == "User"} }
  let(:memo){ types.detect{|t| t.name == "Memo"} }

  context :user do
    subject{ user }
    it{ expect(subject.goon).not_to be_nil }
    it{ expect(subject.goon['id_type']).to eq 'string' }
    it{ expect(subject.goon['id_name']).to eq 'ID' }
    it{ expect(subject.id_name).to eq "ID" }
    it{ expect(subject.id_golang_type).to eq "string" }

    it{ expect(subject.id_definition).to eq 'ID string `datastore:"-" goon:"id" json:"id"`' }
  end

  context :memo do
    subject{ memo }
    it{ expect(subject.goon).not_to be_nil }
    it{ expect(subject.goon['id_type']).to eq 'int64' }
    it{ expect(subject.goon['id_name']).to eq nil }
    it{ expect(subject.id_name).to eq "Id" }
    it{ expect(subject.id_golang_type).to eq "int64" }

    it{ expect(subject.id_definition).to eq 'Id int64 `datastore:"-" goon:"id" json:"id"`' }
  end

end
