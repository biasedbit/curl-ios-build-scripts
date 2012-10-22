module CurlBuilder
  class Cleaner < ConfigurableStep
    include Paths
    include Logging


    # Creation

    def initialize(options = {})
      super options
    end


    # ConfigurableStep

    def log_id
      ' CLEAN '
    end


    # Interface

    def cleanup
      unless setup(:cleanup)
        debug { "Skipping cleanup..." }
        return
      end

      info { "Cleaning up..." }
      FileUtils.rm_rf work_dir

      FileUtils.rm_rf result_dir if setup(:clean_and_exit)
    end
  end
end