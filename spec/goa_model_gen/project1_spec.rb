require 'tmpdir'

require 'json'

require 'goa_model_gen/config'
require 'goa_model_gen/loader'
require 'goa_model_gen/generator'
require 'goa_model_gen/go_struct'

RSpec.describe GoaModelGen::Type do

  let(:config) do
    GoaModelGen::Config.new.tap do |c|
      c.go_package = "github.com/akm/goa_model_gen/project1"
      c.swagger_yaml   = File.expand_path("../project1/swagger/swagger.yaml", __FILE__)
      c.gofmt_disabled = false
      c.model_dir = File.expand_path("../project1/model", __FILE__)
      c.store_dir = File.expand_path("../project1/stores", __FILE__)
      c.converter_dir = File.expand_path("../project1/converters", __FILE__)
      c.fulfill
    end
  end
  let(:generator){ GoaModelGen::Generator.new(config) }

  let(:model_yamls){ Dir.glob(File.expand_path('../project1/design/*.yaml', __FILE__)) }

  let(:loader){ GoaModelGen::Loader.new(config) }
  let(:source_files){ loader.load_files(model_yamls) }
  let(:types){ source_files.map(&:types).flatten }

  let(:user_type){ types.detect{|t| t.name == "UserType"} }
  let(:user){ types.detect{|t| t.name == "User"} }
  let(:memo){ types.detect{|t| t.name == "Memo"} }
  let(:component1){ types.detect{|t| t.name == "Component1"} }
  let(:composite){ types.detect{|t| t.name == "Composite"} }

  def read_expected(path)
    abs_path = File.expand_path(File.join('..', path), __FILE__)
    erb = ERB.new(File.read(abs_path), nil, "-")
    erb.filename = abs_path
    erb.result
  end

  context :user do
    subject{ user }
    it{ expect(subject.goon).not_to be_nil }
    it{ expect(subject.goon['id_type']).to eq 'string' }
    it{ expect(subject.goon['id_name']).to eq 'ID' }
    it{ expect(subject.id_name).to eq "ID" }
    it{ expect(subject.id_golang_type).to eq "string" }

    it{ expect(subject.id_definition).to eq 'ID string `datastore:"-" goon:"id" json:"id"`' }
    it{ expect(subject.use_uuid?).to be_falsy }

    it{ expect(subject.field_by('Email').definition).to eq 'Email string `json:"email" validate:"required,email"`'}
    it{ expect(subject.field_by('AuthDomain').definition).to eq 'AuthDomain string `json:"auth_domain,omitempty"`'}
    it{ expect(subject.field_by('Admin').definition).to eq 'Admin bool `json:"admin,omitempty"`'}
    it{ expect(subject.field_by('ClientId').definition).to eq 'ClientId string `json:"client_id,omitempty"`'}
    it{ expect(subject.field_by('FederatedIdentity').definition).to eq 'FederatedIdentity string `json:"federated_identity,omitempty"`'}
    it{ expect(subject.field_by('FederatedProvider').definition).to eq 'FederatedProvider string `json:"federated_provider,omitempty"`'}
    it{ expect(subject.field_by('CreatedAt').definition).to eq 'CreatedAt time.Time `json:"created_at" validate:"required"`'}
    it{ expect(subject.field_by('UpdatedAt').definition).to eq 'UpdatedAt time.Time `json:"updated_at" validate:"required"`'}

    it :generate do
      Dir.mktmpdir do |dir|
        thor = double(:thor)
        path = File.join(dir, 'user.go')
        generator.source_file = GoaModelGen::SourceFile.new('path/to/user.yaml', [user_type, user])
        generator.thor = thor
        expect(thor).to receive(:create_file).with(path, read_expected('project1/model/user.go'), {skip: false, force: false})
        generator.run('templates/model.go.erb', path)
      end
    end

    it :generate_model do
      generator.source_file = GoaModelGen::SourceFile.new('path/to/user.yaml', [user_type, user])

      puts "user.yaml"
      puts YAML.dump(generator.source_file.types)

      variables = {
        model: user,
        model_package: 'user',
      }
      expect(generator.generate('templates/model.go.erb')).to eq read_expected('project1/model/user.go')
      expect(generator.generate('templates/model_validation.go.erb')).to eq read_expected('project1/model/user_validation.go')
      expect(generator.generate('templates/store.go.erb', variables)).to eq read_expected('project1/stores/user/store.go')
      expect(generator.generate('templates/store_validation.go.erb', variables)).to eq read_expected('project1/stores/user/validation.go')
    end

    it :generate_converter do
      structs = JSON.parse(File.read(File.expand_path('../project1/structs.json', __FILE__)))
      variables = {
        model: GoaModelGen::GoStruct.new(structs['model'].detect{|m| m['Name'] == 'User'}),
        payload: GoaModelGen::GoStruct.new(structs['payload'].detect{|m| m['Name'] == 'UserPayload'}),
        result: GoaModelGen::GoStruct.new(structs['result'].detect{|m| m['Name'] == 'User'}),
      }
      expect(generator.generate('templates/converter.go.erb', variables)).to eq read_expected('project1/converters/user/conv.go')
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
    it{ expect(subject.field_by('ContentText').definition).to eq 'ContentText string `json:"content_text,omitempty"`'}
    it{ expect(subject.field_by('Shared').definition).to eq 'Shared bool `json:"shared,omitempty"`'}
    it{ expect(subject.field_by('CreatedAt').definition).to eq 'CreatedAt time.Time `json:"created_at" validate:"required"`'}
    it{ expect(subject.field_by('UpdatedAt').definition).to eq 'UpdatedAt time.Time `json:"updated_at" validate:"required"`'}

    it :generate_model do
      variables = {
        model: memo,
        model_package: 'memo',
      }
      generator.source_file = GoaModelGen::SourceFile.new('path/to/memo.yaml', [memo])
      expect(generator.generate('templates/model.go.erb')).to eq read_expected('project1/model/memo.go')
      expect(generator.generate('templates/model_validation.go.erb')). to eq read_expected('project1/model/memo_validation.go')
      expect(generator.generate('templates/store.go.erb', variables)).to eq read_expected('project1/stores/memo/store.go')
      expect(generator.generate('templates/store_validation.go.erb', variables)).to eq read_expected('project1/stores/memo/validation.go')
    end

    it :generate_converter do
      structs = JSON.parse(File.read(File.expand_path('../project1/structs.json', __FILE__)))
      variables = {
        model: GoaModelGen::GoStruct.new(structs['model'].detect{|m| m['Name'] == 'Memo'}),
        payload: GoaModelGen::GoStruct.new(structs['payload'].detect{|m| m['Name'] == 'MemoPayload'}),
        result: GoaModelGen::GoStruct.new(structs['result'].detect{|m| m['Name'] == 'Memo'}),
      }
      expect(generator.generate('templates/converter.go.erb', variables)).to eq read_expected('project1/converters/memo/conv.go')
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
      generator.source_file = GoaModelGen::SourceFile.new('path/to/component1_only.yaml', [component1])
      expect(generator.generate('templates/model.go.erb')).to eq read_expected('project1/model/component1_only.go')
      expect(generator.generate('templates/model_validation.go.erb')).to eq read_expected('project1/model/component1_only_validation.go')
      # expect(generator.generate('templates/store.go.erb')).to eq read_expected('project1/stores/component1_only/store.go')
      # expect(generator.generate('templates/store_validation.go.erb')).to eq read_expected('project1/stores/component1_only/validation.go')
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
      variables = {
        model: composite,
        model_package: 'composite',
      }
      generator.source_file = GoaModelGen::SourceFile.new('path/to/composite.yaml', [component1, composite])
      expect(generator.generate('templates/model.go.erb')).to eq read_expected('project1/model/composite.go')
      expect(generator.generate('templates/model_validation.go.erb')).to eq read_expected('project1/model/composite_validation.go')
      expect(generator.generate('templates/store.go.erb', variables)).to eq read_expected('project1/stores/composite/store.go')
      expect(generator.generate('templates/store_validation.go.erb', variables)).to eq read_expected('project1/stores/composite/validation.go')
    end
  end

end
