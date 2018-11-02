require 'goa_model_gen/golang_helper'

RSpec.describe GoaModelGen::GolangHelper do
  subject{ GoaModelGen::GolangHelper.new }

  describe :partition do
    {
      [] => [],
      %w[time fmt] => [%w[fmt time]],

      %w[time fmt golang.org/x/net/context] \
      => [%w[fmt time], %w[golang.org/x/net/context]],

      %w[time fmt golang.org/x/net/context google.golang.org/appengine/datastore google.golang.org/appengine/log github.com/goadesign/goa/uuid] \
      => [
        %w[fmt time],
        %w[golang.org/x/net/context],
        %w[google.golang.org/appengine/datastore google.golang.org/appengine/log],
        %w[github.com/goadesign/goa/uuid],
      ],
    }.each do |arg, expect|
      it "process #{arg.inspect}" do
        expect(subject.partition(arg)).to eq expect
      end
    end
  end

end
