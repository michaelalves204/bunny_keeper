# frozen_string_literal: true

require_relative "concurrency_consumer"
require_relative "notification"
require_relative "yml_serializer"
require_relative "../logger_service"
require_relative "../../bunny_keeper"

module Services
  # Services::Supervisor is responsible for supervising RabbitMQ consumers.
  # It creates, monitors, and automatically restarts consumers in case of failures,
  # as well as terminating the process when the maximum number of restarts is reached.
  class Supervisor
    def initialize
      @restarts = 0
    end

    def call
      execute_consumers

      loop do
        close_process if @restarts >= max_restarts

        concurrency_consumer::CONSUMERS.each do |consumer|
          restart_consumer(consumer[0]) unless consumer[1].alive?
        end

        sleep heartbeat
      end
    end

    private

    def close_process
      Services::Notification.new(config_serializer, contexts, @restarts).call

      logger_service.info("[Close process] restarts #{@restarts}")

      exit
    end

    def restart_consumer(queue)
      @restarts += 1

      logger_service.warn("[Restart process] queue: #{queue} restarts: #{@restarts}")

      create_consumer(queue)
    end

    def concurrency_consumer
      Services::ConcurrencyConsumer
    end

    def execute_consumers
      contexts.each do |context|
        queues = config_serializer.dig("contexts", context, "queues")

        raise BunnyKeeper::QueueNotFound, context unless queues

        queues.each do |queue|
          logger_service.info("Create consumer in Queue: #{queue} - Context: #{context}")

          create_consumer(queue)
        end
      end
    end

    def create_consumer(queue)
      raise BunnyKeeper::QueueNotFound unless config_serializer["queues"]

      concurrency_consumer.new(
        consumer: config_serializer.dig("queues", queue),
        queue_name: queue,
        logger: logger_service
      ).call
    end

    def heartbeat
      config_serializer["heartbeat"] || 5
    end

    def max_restarts
      config_serializer["max_restarts"] || 3
    end

    def contexts
      config_serializer["contexts"].keys
    rescue StandardError
      raise BunnyKeeper::ContextNotFound
    end

    def config_serializer
      @config_serializer ||= Services::YmlSerializer.new.call
    end

    def logger_service
      LoggerService.new(
        max_size_mb: config_serializer.dig("logging", "max_size"),
        shift_count: config_serializer.dig("logging", "shift_count"),
        file_path: config_serializer.dig("logging", "path")
      )
    end
  end
end
