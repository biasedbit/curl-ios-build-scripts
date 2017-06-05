module CurlBuilder
  class Packer < ConfigurableStep

    # Creation

    def initialize(options = {})
      super options
    end


    # Logging

    def log_id
      "PACKAGE"
    end


    # Interface

    def pack(compiled_architectures)
      info { "Packing binaries for architectures '#{param(compiled_architectures.join(" "))}'..." }

      osx = setup(:osx_sdk_version) != "none" ? compiled_architectures.select { |arch| arch.match(/^x86_64/) } : []
      ios = compiled_architectures - osx
      arm = ios.select { |arch| arch.match(/^arm/) }
      arm64 = ios.select { |arch| arch.match(/^arm64/) }
 
      successful = {}

      if create_binary_for osx, "osx"
        successful["osx"] = osx
        copy_include_dir osx.first, "osx"
      end

      if create_binary_for ios, "ios-dev"
        successful["ios-dev"] = ios
        copy_include_dir ios.first, "ios-dev"
      end

      if create_binary_for arm, "ios-appstore"
        successful["ios-appstore"] = arm 
        copy_include_dir arm.first, "ios-appstore"
      end

      if arm64.count > 0
        copy_include_dir arm64.first, "ios64-dev"
      end

      successful
    end


    private
    def copy_include_dir(architecture, name)
      target_dir = result_include_dir(name)
      FileUtils.mkdir_p target_dir
      files_to_copy = File.join output_dir_for(architecture), "include", "curl"

      copy_command = "cp -R #{files_to_copy} #{target_dir}"
      setup(:verbose) ? system(copy_command) : `#{copy_command} &>/dev/null`
      raise Errors::TaskError, "Failed to copy include dir from build to result directory" unless $?.success?

      $?.success?
    end

    def create_binary_for(archs, name)
      return if archs.empty? || archs.nil?

      info {
        "Creating binary #{archs.size > 1 ? "with combined architectures" : "for architecture"} " + 
          "#{param(archs.join(", "))} (#{name})..."
      }

      binaries = archs.collect { |arch| binary_path_for arch }

      FileUtils.mkdir_p result_lib_dir name

      `lipo -create #{binaries.join(" ")} -output #{packed_lib_path_with name} &>/dev/null`
      warn { "Failed to pack '#{param(name)}' binary (archs: #{param(archs.join(", "))})." } unless $?.success?

      $?.success?
    end
  end
end
