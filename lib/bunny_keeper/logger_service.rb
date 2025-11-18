# frozen_string_literal: true

require "logger"
require "fileutils"

# Provides a lightweight logging wrapper with log rotation,
# console output, and formatted timestamps for BunnyKeeper.
class LoggerService
  attr_reader :logger

  def initialize(max_size_mb: 5, shift_count: 1, file_path: "logs/bunny_keeper.log")
    ensure_log_folder(file_path)

    max_bytes = max_size_mb * 1024 * 1024
    @logger = Logger.new(file_path, shift_count, max_bytes)
    logger.level = Logger::INFO
    logger.formatter = proc do |severity, datetime, _progname, msg|
      "[#{datetime.strftime("%Y-%m-%d %H:%M:%S")}] #{severity} : #{msg}\n"
    end
  end

  def info(message)
    output_log("INFO", message)

    logger.info(message)
  end

  def warn(message)
    output_log("WARNING", message)

    logger.warn(message)
  end

  def error(message)
    output_log("ERROR", message)

    logger.error(message)
  end

  private

  def output_log(severity, message)
    puts("[BunnyKeeper][#{Time.now}] #{severity} : #{message}")
  end

  def ensure_log_folder(file_path)
    folder = File.dirname(file_path)
    FileUtils.mkdir_p(folder) unless Dir.exist?(folder)
  end
end
