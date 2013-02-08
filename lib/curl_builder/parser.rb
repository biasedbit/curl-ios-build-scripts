module CurlBuilder
  # Parse input and build script options.
  #
  # Usage:
  #
  #   options = Parser.new(args: ARGV).work
  #   options[:protocols]          # returns the configured protocols
  #   options[:flags]              # returns the configured compilation flags (sans protocols)
  #   options[:defaults]           # returns the parameters for the execution of this script
  #
  #
  # You may optionally pass default protocols, flags and defaults by initializing a new instance
  # with an an option Hash:
  #
  #   Parser.new(protocols: {http: true}, flags: {some_flag: false})
  #
  class Parser
    include Logging


    attr_reader :protocols
    attr_reader :flags
    attr_reader :setup


    # Creation

    def initialize(options = {})
      @protocols = options.fetch(:protocols) { DEFAULT_PROTOCOLS.dup }
      @flags     = options.fetch(:flags) { DEFAULT_FLAGS.dup }
      @setup     = options.fetch(:setup) { DEFAULT_SETUP.dup }
    end


    # Interface

    def parse(args)
      parser = OptionParser.new { |parser|
        parser.banner = "Usage: build_curl [options]"

        parser.separator ""
        parser.separator "Specific options:"

        parser.on("--libcurl-version VERSION",
                  "Use specific libcurl version or 'master' to download latest from github",
                  "  Defaults to #{param(setup[:libcurl_version])}") do |version|
          setup[:libcurl_version] = version
        end

        parser.on("--[no-]debug-symbols",
                  "Include or exclude debug symbols",
                  "  Defaults to #{param(setup[:debug_symbols])}") do |debug_symbols|
          setup[:debug_symbols] = debug_symbols
        end

        parser.on("--[no-]curldebug",
                  "Use CURLDEBUG flag when building",
                  "  Defaults to #{param(setup[:curldebug])}") do |curldebug|
          setup[:curldebug] = curldebug
        end

        parser.on("--archs X,Y,Z",
                  Array,
                  "Which architectures to compile for (i386, armv6, armv7 and/or armv7s)",
                  "  Defaults to #{param(setup[:architectures].join(","))}") do |archs|
          # filter out unknown architectures to avoid build errors...
          setup[:architectures] = CurlBuilder.filter_valid_archs(archs)
        end

        parser.on("--enable-protocols A,B,C",
                  Array,
                  "Enables a list of protocols",
                  "  Defaults to #{param(protocols.select { |k, enabled| enabled }.keys.join(", "))}") do |enabled|
          enabled.each do |p|
            protocols[p] = true
          end
        end

        parser.on("--disable-protocols A,B,C",
                  Array,
                  "Disables a list of protocols",
                  "  Defaults to #{param(protocols.select { |k, enabled| !enabled }.keys.join(", "))}") do |enabled|
          enabled.each do |p|
            protocols[p] = false
          end
        end

        parser.on("--sdk-version SDK",
                  "Use specific SDK version",
                  "  Defaults to #{param(setup[:sdk_version])}") do |sdk|
          setup[:sdk_version] = sdk
        end

        parser.on("--osx-sdk-version SDK",
                  "Use specific SDK version",
                  "  Defaults to #{param(setup[:osx_sdk_version])}") do |sdk|
          setup[:osx_sdk_version] = sdk
        end

        parser.on("--log-level LOG_LEVEL",
                  %w(debug info warn error),
                  "Log level for build process",
                  "  Defaults to #{param(setup[:log_level])}") do |log_level|
          setup[:log_level] = log_level
        end

        parser.on("--run-dir RUN_DIR",
                  "Specify directory where script will run",
                  "  Defaults to #{param(setup[:run_on_dir])}") do |run_on_dir|
          setup[:run_on_dir] = run_on_dir
        end

        parser.on("--work-dir WORK_DIR",
                  "Specify the name of the work directory",
                  "  Defaults to #{param(setup[:work_dir])}") do |work_dir|
          setup[:work_dir] = work_dir
        end

        parser.on("--result-dir WORK_DIR",
                  "Specify the name of the result directory",
                  "  Defaults to #{param(setup[:result_dir])}") do |result_dir|
          setup[:result_dir] = result_dir
        end

        parser.on("--xcode-home XCODE_HOME",
                  "Specify Xcode home directory; if this is an invalid path, script will revert to using xcode-select",
                  "  Defaults to #{param(setup[:xcode_home])}") do |xcode_home|
          setup[:xcode_home] = xcode_home
        end

        parser.on("--verbose", "Verbose output") do
          setup[:verbose] = true
        end

        parser.on("--[no-]cleanup",
                  "Clean up work directory after completion",
                  "  Defaults to #{param(setup[:cleanup])}") do |cleanup|
          setup[:cleanup] = cleanup
        end

        parser.on("--clean",
                  "Perform cleanup only",
                  "  When set, script will only force deletion of work and result directories and exit") do
          setup[:cleanup]        = true # forces cleanup
          setup[:clean_and_exit] = true
        end

        parser.on("-h", "--help") { puts parser; exit }
      }

      parser.parse(args)

      {setup: setup, protocols: protocols, flags: flags}
    end
  end
end