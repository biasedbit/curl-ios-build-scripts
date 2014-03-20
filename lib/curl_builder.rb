require "logger"
require "optparse"
require "fileutils"
require "open3"


require_relative "curl_builder/errors"
require_relative "curl_builder/paths"
require_relative "curl_builder/logging"
require_relative "curl_builder/configurable_step"

# Steps
require_relative "curl_builder/parser"
require_relative "curl_builder/preparer"
require_relative "curl_builder/compiler"
require_relative "curl_builder/packer"
require_relative "curl_builder/cleaner"


# Phases
#   1. Read stdin: Parser
#   2. Download lib and create folders: Preparer
#   3. For each arch, compile: Compiler
#   4. Create output: Wrapper
#   5. Cleanup: Cleaner

module CurlBuilder
  extend self


  # Defaults

  DEFAULT_PROTOCOLS = {
    "http"   => true,
    "rtsp"   => false,
    "ftp"    => false,
    "file"   => false,
    "ldap"   => false,
    "ldaps"  => false,
    "rtsp"   => false,
    "dict"   => false,
    "telnet" => false,
    "tftp"   => false,
    "pop3"   => false,
    "imap"   => false,
    "smtp"   => false,
    "gopher" => false
  }

  DEFAULT_FLAGS = {
    "darwinssl" => true,
    "ssl"       => false,
    "libssh2"   => false,
    "librtmp"   => false,
    "libidn"    => false,
    "ca-bundle" => false
  }

  DEFAULT_SETUP = {
    log_level:          "info", # debug, info, warn, error
    verbose:            false,
    debug_symbols:      false,
    curldebug:          false,
    sdk_version:        "7.0",
    osx_sdk_version:    "10.8",
    libcurl_version:    "7.32.0",
    architectures:      %w(i386 armv7 armv7s arm64 x86_64),
    xcode_home:         "/Applications/Xcode.app/Contents/Developer",
    run_on_dir:         Dir::pwd,
    work_dir:           "build",
    result_dir:         "curl",
    clean_and_exit:     false,
    cleanup:            true,
  }

  VALID_ARGS = {architectures: %w(i386 armv7 armv7s arm64 x86_64)}


  attr_accessor :logger


  def logger
    @logger ||= Logger.new($stdout)
  end


  # Helper functions

  def build_protocols(protocols)
    protocols.collect { |protocol, enabled| enabled ? "--enable-#{protocol}" : "--disable-#{protocol}" }
  end

  def build_flags(flags)
    flags.collect { |flag, enabled| enabled ? "--with-#{flag}" : "--without-#{flag}" }
  end

  def filter_valid_archs(archs)
    VALID_ARGS[:architectures] & archs
  end
end
