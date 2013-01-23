module CurlBuilder
  class Preparer < ConfigurableStep
    include Paths
    include Logging


    # Creation

    def initialize(options = {})
      super options
    end


    # Logging

    def log_id
      "PREPARE"
    end


    # Interface

    def prepare
      setup_tools

      info { "Setting up work directory..." }
      setup_work_directory

      if archive_exists?
        info { "Archive already exists, expanding..." }
      else
        info { "Downloading archive for libcurl version #{param(setup(:libcurl_version))}" }
        download
        info { "Archive downloaded, expanding..." }
      end

      unpack
      info { "Archive expanded." }
    end


    private
    def setup_tools
      unless File.exists? setup(:xcode_home)
        warn {
          "Provided Xcode path ('#{param(setup(:xcode_home))}') does not exist; " +
            "using xcode-select to find a valid one..."
        }
        xcode_path = `xcode-select --print-path`.strip
        raise Errors::TaskError, "Could not find Xcode path - make sure you have Xcode installed" unless $?.success?
        configuration[:setup][:xcode_home] = xcode_path
      end

      info { "Using Xcode at '#{param(setup(:xcode_home))}'..." }
    end

    def setup_work_directory
      # These directories are set on Paths module
      FileUtils.mkdir_p [work_dir, download_dir, source_dir, result_dir]
    end

    def download
      if setup(:libcurl_version) == "master"
        download_file = "https://github.com/bagder/curl/archive/master.tar.gz"
      else
        download_file = "http://curl.haxx.se/download/curl-#{setup(:libcurl_version)}.tar.gz"
      end
      # redirect output to /dev/null unless we"re in verbose mode
      command = "curl -Lo #{archive_path} #{download_file} #{setup(:verbose) ? "" : "1>&/dev/null"}"
      output = `#{command}`
      raise Errors::TaskError, "Could not download '#{download_file}'" unless $?.success?
    end

    def unpack
      output = `tar -xzf #{archive_path} -C #{source_dir} 2>&1`
      raise Errors::TaskError, "Could not unpack libcurl file: '#{output.strip}'" unless $?.success?
    end

    def archive_exists?
      exists = File.exists? archive_path
    end
  end
end