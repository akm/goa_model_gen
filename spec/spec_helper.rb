require "bundler/setup"
require "goa_model_gen"
require "goa_model_gen/logger"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  GoaModelGen::Logger.setup(ENV['LOG_LEVEL'] || 'warn')
end
