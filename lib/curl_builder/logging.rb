module CurlBuilder
  module Logging
    def debug(&block)
      #CurlBuilder.logger.debug(log_id, &block)
      return unless CurlBuilder.logger.level <= Logger::DEBUG
      puts "[#{blue(log_id)}] #{cyan("DEBUG")} - #{block.call.to_s}"
    end

    def info(&block)
      #CurlBuilder.logger.info(log_id, &block)
      return unless CurlBuilder.logger.level <= Logger::INFO
      puts "[#{blue(log_id)}]  #{green("INFO")} - #{block.call.to_s}"
    end

    def warn(&block)
      return unless CurlBuilder.logger.level <= Logger::WARN
      puts "[#{blue(log_id)}]  #{yellow("WARN")} - #{block.call.to_s}"
    end

    def error(&block)
      #CurlBuilder.logger.error(log_id, &block)
      return unless CurlBuilder.logger.level <= Logger::ERROR
      puts "[#{blue(log_id)}] #{red("ERROR")} - #{block.call.to_s}"
    end

    # Override for a different id
    def log_id
      self.class.name.split("::").last
    end

    def bold(text)
      "\e[1m#{text}\e[22m"
    end

    def colorize(text, color)
      "\e[#{color}m#{text}\e[0m"
    end

    def black(text); colorize(text, "30"); end
    def red(text); colorize(text, "31"); end
    def green(text); colorize(text, "32"); end
    def yellow(text); colorize(text, "33"); end
    def blue(text); colorize(text, "34"); end
    def magenta(text); colorize(text, "35"); end
    def cyan(text); colorize(text, "36"); end
    def gray(text); colorize(text, "37"); end
    def param(text); bold(gray(text)); end
  end
end
