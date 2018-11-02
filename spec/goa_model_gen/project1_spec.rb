require 'tmpdir'

require 'goa_model_gen/config'
require 'goa_model_gen/loader'
require 'goa_model_gen/generator'

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
  let(:generator){ GoaModelGen::Generator.new(config) }

  let(:model_yamls){ Dir.glob(File.expand_path('../project1/design/*.yaml', __FILE__)) }

  let(:loader){ GoaModelGen::Loader.new(config) }
  let(:source_files){ loader.load_types(model_yamls) }
  let(:types){ source_files.map(&:types).flatten }

  let(:user){ types.detect{|t| t.name == "User"} }
  let(:memo){ types.detect{|t| t.name == "Memo"} }
  let(:component1){ types.detect{|t| t.name == "Component1"} }
  let(:composite){ types.detect{|t| t.name == "Composite"} }


  context :user do
    subject{ user }
    it{ expect(subject.goon).not_to be_nil }
    it{ expect(subject.goon['id_type']).to eq 'string' }
    it{ expect(subject.goon['id_name']).to eq 'ID' }
    it{ expect(subject.id_name).to eq "ID" }
    it{ expect(subject.id_golang_type).to eq "string" }

    it{ expect(subject.id_definition).to eq 'ID string `datastore:"-" goon:"id" json:"id"`' }
    it{ expect(subject.use_uuid?).to be_falsy }

    it{ expect(subject.field_by('Email').definition).to eq 'Email string `json:"email,omitempty"`'}
    it{ expect(subject.field_by('AuthDomain').definition).to eq 'AuthDomain string `json:"auth_domain,omitempty"`'}
    it{ expect(subject.field_by('Admin').definition).to eq 'Admin bool `json:"admin,omitempty"`'}
    it{ expect(subject.field_by('ClientID').definition).to eq 'ClientID string `json:"client_id,omitempty"`'}
    it{ expect(subject.field_by('FederatedIdentity').definition).to eq 'FederatedIdentity string `json:"federated_identity,omitempty"`'}
    it{ expect(subject.field_by('FederatedProvider').definition).to eq 'FederatedProvider string `json:"federated_provider,omitempty"`'}
    it{ expect(subject.field_by('CreatedAt').definition).to eq 'CreatedAt time.Time `json:"created_at" validate:"required"`'}
    it{ expect(subject.field_by('UpdatedAt').definition).to eq 'UpdatedAt time.Time `json:"updated_at" validate:"required"`'}

    it :generate do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'user.go')
        generator.types = [user]
        generator.run('templates/model.go.erb', path)
        expect(File.read(path)).to eq File.read(File.expand_path('../project1/model/user.go', __FILE__))
      end
    end

    it :generate_model do
      generator.types = [user]
      expect(generator.generate('templates/model.go.erb')).to eq File.read(File.expand_path('../project1/model/user.go', __FILE__))
      expect(generator.generate('templates/model_validation.go.erb')).to eq File.read(File.expand_path('../project1/model/user_validation.go', __FILE__))
    end
  end

  context :memo do
    subject{ memo }
    it{ expect(subject.goon).not_to be_nil }
    it{ expect(subject.goon['id_type']).to eq 'int64' }
    it{ expect(subject.goon['id_name']).to eq nil }
    it{ expect(subject.id_name).to eq "Id" }
    it{ expect(subject.id_golang_type).to eq "int64" }

    it{ expect(subject.id_definition).to eq 'Id int64 `datastore:"-" goon:"id" json:"id"`' }
    it{ expect(subject.use_uuid?).to be_falsy }

    it{ expect(subject.field_by('AuthorKey').definition).to eq 'AuthorKey *datastore.Key `json:"author_key" validate:"required"`'}
    it{ expect(subject.field_by('Content').definition).to eq 'Content string `json:"content,omitempty"`'}
    it{ expect(subject.field_by('Shared').definition).to eq 'Shared bool `json:"shared,omitempty"`'}
    it{ expect(subject.field_by('CreatedAt').definition).to eq 'CreatedAt time.Time `json:"created_at" validate:"required"`'}
    it{ expect(subject.field_by('UpdatedAt').definition).to eq 'UpdatedAt time.Time `json:"updated_at" validate:"required"`'}

    it :generate_model do
      generator.types = [memo]
      expect(generator.generate('templates/model.go.erb')).to eq File.read(File.expand_path('../project1/model/memo.go', __FILE__))
      expect(generator.generate('templates/model_validation.go.erb')). to eq File.read(File.expand_path('../project1/model/memo_validation.go', __FILE__))
    end
  end

  context :component1 do
    subject{ component1 }
    it{ expect(subject.goon).to be_nil }
    it{ expect(subject.id_name).to eq nil }
    it{ expect(subject.id_golang_type).to eq nil }

    it{ expect(subject.id_definition).to eq nil }
    it{ expect(subject.use_uuid?).to be_falsy }

    it{ expect(subject.field_by('Name').definition).to eq 'Name string `json:"name" validate:"required"`'}

    it :generate_model do
      generator.types = [component1]
      expect(generator.generate('templates/model.go.erb')).to eq File.read(File.expand_path('../project1/model/component1_only.go', __FILE__))
      expect(generator.generate('templates/model_validation.go.erb')).to eq File.read(File.expand_path('../project1/model/component1_only_validation.go', __FILE__))
    end
  end

  context :composite do
    subject{ composite }
    it{ expect(subject.goon).not_to be_nil }
    it{ expect(subject.goon['id_type']).to eq 'UUID' }
    it{ expect(subject.goon['id_name']).to eq nil }
    it{ expect(subject.id_name).to eq "Id" }
    it{ expect(subject.id_golang_type).to eq "string" }

    it{ expect(subject.id_definition).to eq 'Id string `datastore:"-" goon:"id" json:"id"`' }
    it{ expect(subject.use_uuid?).to be_truthy }

    it{ expect(subject.field_by('MainComponent').definition).to eq 'MainComponent Component1 `json:"main_component" validate:"required"`'}
    it{ expect(subject.field_by('Components').definition).to eq 'Components []Component1 `json:"components,omitempty"`'}

    it :generate do
      generator.types = [component1, composite]
      expect(generator.generate('templates/model.go.erb')).to eq File.read(File.expand_path('../project1/model/composite.go', __FILE__))
      expect(generator.generate('templates/model_validation.go.erb')).to eq File.read(File.expand_path('../project1/model/composite_validation.go', __FILE__))
    end
  end

end
