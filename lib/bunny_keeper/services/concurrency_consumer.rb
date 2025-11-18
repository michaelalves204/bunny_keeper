# frozen_string_literal: true

require_relative "../../bunny_keeper"
require_relative "task_executor"

module Services
  # Manages and runs queue consumers concurrently, spawning a thread per consumer
  # and executing the configured handler class and method.
  class ConcurrencyConsumer
    CONSUMERS = {}

    def initialize(consumer:, queue_name:, logger:)
      @consumer = consumer
      @queue_name = queue_name
      @logger = logger
    end

    def call
      @logger.info("Initializing #{@consumer}")

      CONSUMERS[@queue_name] = Thread.new do
        tasks_executor_service
      rescue StandardError => e
        @logger.error("#{@queue_name}: #{e.class} - #{e.message}")

        exit
      end
    end

    private

    attr_reader :consumer

    def tasks_executor_service
      Services::TaskExecutor.new(
        class_name: class_name,
        method_name: method,
        args: args
      ).call!
    end

    def class_name
      required_string("handler_class", BunnyKeeper::ConfigHandlerClassNotFound)
    end

    def method
      required_string("method", BunnyKeeper::ConfigMethodNotFound)
    end

    def args
      consumer["parameters"] || {}
    end

    def required_string(key, error_klass)
      value = consumer[key]

      raise error_klass, @queue_name if value.nil? || value.to_s.strip.empty?

      value.to_s.strip
    end
  end
end
