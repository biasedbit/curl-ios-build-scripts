module CurlBuilder
  class Packer < ConfigurableStep

    # Creation

    def initialize(options = {})
      super options
    end


    # Logging

    def log_id
      'PACKAGE'
    end


    # Interface

    def pack(compiled_architectures)
      info { "Packing binaries for architectures '#{param(compiled_architectures.join(' '))}'..." }

      copy_include_dir compiled_architectures.first

      all_arm = compiled_architectures.select { |arch| arch.match(/^arm/) }

      successful = {}
      successful['all'] = compiled_architectures if create_binary_for compiled_architectures, 'all'

      unless all_arm.empty?
        successful['arm'] = all_arm if create_binary_for all_arm, 'arm'
      end

      if compiled_architectures.include?('i386')
        successful['i386'] = %w(i386) if create_binary_for %w(i386), 'i386'
      end

      successful
    end


    private
    def copy_include_dir(architecture)
      copy_command = "cp -R #{File.join output_dir_for(architecture), 'include', 'curl', '*'} #{result_include_dir}"
      setup(:verbose) ? system(copy_command) : `#{copy_command} &>/dev/null`
      raise Errors::TaskError, "Failed to copy include dir from build to result directory" unless $?.success?

      $?.success?
    end

    def create_binary_for(archs, name)
      info {
        "Creating binary #{archs.size > 1 ? 'with combined architectures' : 'for architecture'} " + 
          "#{param(archs.join(', '))}..."
      }

      binaries = archs.collect { |arch| binary_path_for arch }

      `lipo -create #{binaries.join(' ')} -output #{packed_lib_path_with name} &>/dev/null`
      warn { "Failed to pack '#{param(name)}' binary (archs: #{param(archs.join(', '))})." } unless $?.success?

      $?.success?
    end
  end
end
