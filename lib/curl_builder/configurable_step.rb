module CurlBuilder
  class ConfigurableStep
    include Paths
    include Logging


    attr_reader :configuration


    # Creation

    def initialize(options = {})
      @configuration = options.fetch :configuration
    end


    protected
    def setup(option_name)
      configuration[:setup][option_name]
    end
  end
end
