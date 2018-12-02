require "goa_model_gen"

require "logger"

module GoaModelGen
  class << self
    def logger
      @logger ||= ::Logger.new($stderr)
    end
  end

  module Logger
    class << self
      def setup(log_level)
        GoaModelGen.logger.level =
          case log_level
          when Integer then log_level
          when String then ::Logger::SEV_LABEL.index(log_level.upcase)
          else raise "Unsupported log_level: [#{log_level.class.name}] #{log_level.inspect}"
          end
      end
    end
  end
end
