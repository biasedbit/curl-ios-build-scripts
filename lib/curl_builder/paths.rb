module CurlBuilder
  module Paths
    def work_dir
      @work_dir ||= File.join setup(:run_on_dir), "build"
    end

    def download_dir
      @download_dir ||= File.join work_dir, "download"
    end

    def source_dir
      @source_dir ||= File.join work_dir, "source"
    end

    def expanded_archive_dir
      @configure_binary ||= File.join source_dir, "curl-#{setup(:libcurl_version)}"
    end

    def archive_name
      @archive_name ||= "libcurl-#{setup(:libcurl_version)}.tar.gz"
    end

    def archive_path
      @archive_path ||= File.join download_dir, archive_name
    end

    def output_dir_for(architecture)
      File.join work_dir, "out", architecture
    end

    def binary_path_for(architecture)
      File.join output_dir_for(architecture), "lib", "libcurl.a"
    end

    def result_dir
      File.join setup(:run_on_dir), "curl"
    end

    def result_lib_dir(name)
      File.join result_dir, name, "lib"
    end

    def result_include_dir(name)
      File.join result_dir, name, "include"
    end

    def packed_lib_path_with(name)
      File.join result_lib_dir(name), "libcurl.a"
    end
  end
end
