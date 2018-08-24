require 'goa_model_gen/field'
require 'goa_model_gen/type'

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

  describe :custom? do
    GoaModelGen::Field::PRIMITIVE_TYPES.each do |t|
      it(t.inspect) { expect(GoaModelGen::Field.new('f', 'type' => t)).not_to be_custom }
    end

    it(:custom) { expect(GoaModelGen::Field.new('f', 'type' => "CustomDefinedType")).to be_custom }
  end

  describe :not_null? do
    [
      {input: {'required' => true, 'default' => 'x' }, optional: false, nullable: false},
      {input: {'required' => true, 'default' => nil }, optional: false, nullable: false},
      {input: {'required' => false, 'default' => 'x'}, optional: true , nullable: false},
      {input: {'required' => false, 'default' => nil}, optional: true , nullable: true },
    ].each do |d|
      context d do
        subject{ GoaModelGen::Field.new('f', d[:input].merge('type' => "string")) }
        it { expect(subject.optional?).to eq d[:optional] }
        it { expect(subject.nullable?).to eq d[:nullable] }
        it { expect(subject.not_null?).to eq !d[:nullable] }
      end
    end
  end


  let(:f_str  ){ GoaModelGen::Field.new("f", 'type' => 'string') }
  let(:f_bool ){ GoaModelGen::Field.new("f", 'type' => 'bool') }
  let(:f_int  ){ GoaModelGen::Field.new("f", 'type' => 'int') }
  let(:f_time ){ GoaModelGen::Field.new("f", 'type' => 'time.Time') }
  let(:f_dskey){ GoaModelGen::Field.new("f", 'type' => '*datastore.Key') }
  let(:f_custom){ GoaModelGen::Field.new("f", 'type' => 'CustomType1') }

  let(:string_base_type1){ GoaModelGen::Model.new('StringBaseType1', 'base' => 'string') }
  let(:int_base_type1){ GoaModelGen::Model.new('IntBaseType1', 'base' => 'int') }

  describe :payload_assignment_options do
    let(:pf_str  ){ GoaModelGen::Field.new("f", 'type' => 'string') }
    let(:pf_bool ){ GoaModelGen::Field.new("f", 'type' => 'boolean') }
    let(:pf_int  ){ GoaModelGen::Field.new("f", 'type' => 'integer', 'format' => 'int64') }
    let(:pf_time ){ GoaModelGen::Field.new("f", 'type' => 'string', 'format' => 'date-time') }
    let(:pf_custom){ GoaModelGen::Field.new("f", 'type' => '') }

    [false, true].each do |field_required|
      context "model_field_required: #{field_required.inspect}" do
        context "same type" do
          [:str, :bool, :int, :time].each do |base_type|
            it base_type do
              pf = send(:"pf_#{base_type}").tap{|pf| pf.required = true}
              f = send(:"f_#{base_type}").tap{|f| f.required = field_required}
              simple, with_error, method_name = f.payload_assignment_options(pf)
              expect(simple).to be_truthy
              expect(with_error).to be_nil
              expect(method_name).to be_nil
            end
          end
        end

        context "nullable" do
          {
            str: 'StringPointerToString',
            bool: 'BoolPointerToBool',
            int: 'IntPointerToInt',
            time: 'TimePointerToTime',
          }.each do |base_type, method_name|
            it base_type do
              pf = send(:"pf_#{base_type}").tap{|pf| pf.required = false}
              f = send(:"f_#{base_type}").tap{|f| f.required = field_required}
              simple, with_error, method_name = f.payload_assignment_options(pf)
              expect(simple).to be_falsy
              expect(with_error).to be_falsy
              expect(method_name).to eq method_name
            end
          end
        end

        context "derived_type" do
          [
            {required: true , methods: 'StringBaseType1'},
            {required: false, methods: ['StringPointerToString','StringBaseType1'] },
          ].each do |ptn|
            it "string base" do
              pf = pf_str.tap{|pf| pf.required = ptn[:required]}
              f = GoaModelGen::Field.new("f", 'type' => string_base_type1.name, 'required' => field_required)
              f.assign_type_base(f.type => string_base_type1)
              simple, with_error, method_name = f.payload_assignment_options(pf)
              expect(simple).to be_falsy
              expect(with_error).to be_falsy
              expect(method_name).to eq ptn[:methods]
            end
          end

          [
            {required: true , methods: 'IntBaseType1'},
            {required: false, methods: ['IntPointerToInt', 'IntBaseType1'] },
          ].each do |ptn|
            it "int base" do
              pf = pf_int.tap{|pf| pf.required = ptn[:required]}
              f = GoaModelGen::Field.new("f", 'type' => int_base_type1.name, 'required' => field_required)
              f.assign_type_base(f.type => int_base_type1)
              simple, with_error, method_name = f.payload_assignment_options(pf)
              expect(simple).to be_falsy
              expect(with_error).to be_falsy
              expect(method_name).to eq ptn[:methods]
            end
          end
        end

        context "custom" do
          it "custom" do
            pf = pf_custom.tap{|pf| pf.required = true}
            f = f_custom.tap{|f| f.required = field_required}
            simple, with_error, method_name = f.payload_assignment_options(pf)
            expect(simple).to be_falsy
            expect(with_error).to be_truthy
            expect(method_name).to eq "CustomType1PayloadToModel"
          end
        end

        context "formatting" do
          it "int" do
            pf = pf_int.tap{|pf| pf.required = true}
            f = f_str.tap{|f| f.required = field_required}
            simple, with_error, method_name = f.payload_assignment_options(pf)
            expect(simple).to be_falsy
            expect(with_error).to be_falsy
            expect(method_name).to eq "IntToString"
          end
        end

        context "parsing" do
          it "datastore.Key" do
            pf = pf_str.tap{|pf| pf.required = false}
            f = f_dskey.tap{|f| f.required = field_required}
            simple, with_error, method_name = f.payload_assignment_options(pf)
            expect(simple).to be_falsy
            expect(with_error).to be_truthy
            expect(method_name).to eq "StringPointerToDatastoreKeyPointer"
          end

          it "int" do
            pf = pf_str.tap{|pf| pf.required = true}
            f = f_int.tap{|f| f.required = field_required}
            simple, with_error, method_name = f.payload_assignment_options(pf)
            expect(simple).to be_falsy
            expect(with_error).to be_truthy
            expect(method_name).to eq "StringToInt"
          end
        end

      end
    end


  end

end
