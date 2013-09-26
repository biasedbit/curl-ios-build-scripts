module CurlBuilder
  class Compiler < ConfigurableStep

    # Creation

    def initialize(options = {})
      super options
    end


    # Logging

    def log_id
      "COMPILE"
    end


    # Interface

    def compile
      info { "Attempting to compile for architectures: #{setup(:architectures).join(", ")}..." }

      # Attempt to compile all architectures and return a list of the ones that were successful
      setup(:architectures).collect { |architecture|
        compile_for(architecture) ? architecture : nil
      }.compact
    end


    private
    def compile_for(architecture)
      platform = platform_for architecture
      tools    = tools_for platform
      flags    = compilation_flags_for platform, architecture

      info {
        "Building libcurl #{param(setup(:libcurl_version))} for " +
          "#{param(platform)} #{param(sdk_version_for(platform))} (#{architecture})..."
      }
      debug {
        "Tools:\n  #{tools.collect { |tool, path| "#{magenta(tool.to_s.upcase)}: #{param(path)}" }.join("\n  ")}"
      }
      debug {
        "Flags:\n  #{flags.collect { |flag, value| "#{magenta(flag.to_s.upcase)}: #{param(value)}" }.join("\n  ")}"
      }

      FileUtils.mkdir_p output_dir_for architecture

      ensure_configure_script
      # Bail out and signal failure to avoid passing this architecture to the Packer
      return false unless configure architecture, tools, flags

      # Will return true or false to signal success/failure
      make architecture
    end

    def platform_for(architecture)
      case architecture
      when "x86_64"
        "MacOSX"
      when "i386"
        "iPhoneSimulator"
      else
        "iPhoneOS"
      end
    end

    def tools_for(platform)
      {
        cc:     find_tool("gcc", platform),
        ld:     find_tool("ld", platform),
        ar:     find_tool("ar", platform),
        as:     find_tool("as", platform),
        nm:     find_tool("nm", platform),
        ranlib: find_tool("ranlib", platform)
      }
    end

    def find_tool(tool_name, platform)
      tool = `xcrun -sdk #{platform.downcase} -find #{tool_name}`.strip
      raise Errors::TaskError, "Could not find tool '#{tool_name}': failed to run 'xcrun -find'" unless $?.success?

      tool
    end

    def sdk_version_for(platform)
      if platform == "iPhoneOS" || platform == "iPhoneSimulator"
        setup(:sdk_version)
      else
        setup(:osx_sdk_version)
      end
    end

    def compilation_flags_for(platform, architecture)
      if platform == "iPhoneOS" || platform == "iPhoneSimulator"
        version = architecture == "arm64" ? "6.0" : "5.0"
        min_version = "-miphoneos-version-min=#{version}"
      else
        min_version = "-mmacosx-version-min=10.7"
      end

      sdk_version = sdk_version_for platform
      sdk = "#{setup(:xcode_home)}/Platforms/#{platform}.platform/Developer/SDKs/#{platform}#{sdk_version}.sdk"

      {
        ldflags: "-arch #{architecture} -pipe -isysroot #{sdk}",
        cflags:  "-arch #{architecture} -pipe -isysroot #{sdk} #{min_version}"
      }
    end

    def expand_env_vars(env_vars)
      env_vars.collect { |key, value| "#{key.to_s.upcase}=\"#{value}\"" }.join(" ")
    end

    def ensure_configure_script
      Dir.chdir(expanded_archive_dir) do
        return if File.exists?("configure")

        debug { "configure file not found; creating via ./buildconf" }
        buildconf = "./buildconf"
        setup(:verbose) ? system(buildconf) : `#{buildconf} &>/dev/null`
      end
    end

    def configure(architecture, tools, compilation_flags)
      flags  = CurlBuilder.build_flags(configuration[:flags])
      flags += CurlBuilder.build_protocols(configuration[:protocols])

      flags << "--enable-debug" if setup(:debug_symbols)
      flags << "--enable-curldebug" if setup(:curldebug)

      configure_command = %W{
        #{expand_env_vars(tools)}
        #{expand_env_vars(compilation_flags)}
        ./configure
        --host=#{architecture}-apple-darwin
        --disable-shared
        --enable-static
        #{flags.join(" ")}
        --prefix="#{output_dir_for architecture}"
      }

      flattened_command = configure_command.join(" ")
      debug { "Running configure with command:\n#{param(flattened_command)}" }

      # puts configure_command
      Dir.chdir(expanded_archive_dir) do
        setup(:verbose) ? system(flattened_command) : `#{flattened_command} &>/dev/null`
      end

      warn { "Configuration for architecture '#{param(architecture)}' failed." } unless $?.success?
      $?.success?
    end

    def make(architecture)
      debug { "Compiling..." }
      Dir.chdir(expanded_archive_dir) do
        setup(:verbose) ? system("make && make install") : `make &>/dev/null && make install &>/dev/null`
      end

      warn { "Compilation for architecture '#{param(architecture)}' failed." } unless $?.success?
      $?.success?
    end
  end
end
