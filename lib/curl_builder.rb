require 'logger'
require 'optparse'
require 'fileutils'
require 'open3'


require 'curl_builder/errors'
require 'curl_builder/paths'
require 'curl_builder/logging'
require 'curl_builder/configurable_step'

# Steps
require 'curl_builder/parser'
require 'curl_builder/preparer'
require 'curl_builder/compiler'
require 'curl_builder/packer'
require 'curl_builder/cleaner'


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
    'http'   => true,
    'rtsp'   => false,
    'ftp'    => false,
    'file'   => false,
    'ldap'   => false,
    'ldaps'  => false,
    'rtsp'   => false,
    'dict'   => false,
    'telnet' => false,
    'tftp'   => false,
    'pop3'   => false,
    'imap'   => false,
    'smtp'   => false,
    'gopher' => false
  }

  DEFAULT_FLAGS = {
    'darwinssl' => true,
    'ssl'       => false,
    'libssh2'   => false,
    'librtmp'   => false,
    'libidn'    => false,
    'ca-bundle' => false
  }

  DEFAULT_SETUP = {
<<<<<<< HEAD
    :log_level =>       'info', # debug, info, warn, error
    :verbose =>         false,
    :sdk_version =>     '6.0',
    :libcurl_version => '7.28.1',
    :architectures =>   %w(i386 armv7 armv7s),
    :xcode_home =>      '/Applications/Xcode.app/Contents/Developer',
    :run_on_dir =>      Dir::pwd,
    :work_dir =>        'build',
    :result_dir =>      'curl',
    :clean_and_exit =>  false,
    :cleanup =>         true,
  }

  VALID_ARGS = { :architectures => %w(i386 armv7 armv7s) }

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
