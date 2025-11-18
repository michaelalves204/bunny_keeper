# frozen_string_literal: true

require_relative "../yml_serializer"

module Services
  module Rabbitmq
    # ConsumerInspect provides a lightweight and efficient way to verify
    # whether a specific RabbitMQ consumer (identified by its consumer_tag)
    # is currently active in a given queue. It queries the RabbitMQ
    # Management API and performs in-memory lookup to check consumer status,
    # making it suitable for fast health-check operations.
    class ConsumerInspect
      def initialize(queue_name, consumer_tag)
        @queue_name = queue_name
        @consumer_tag = consumer_tag
      end

      def exists?
        return false unless config_serializer

        consumer_active?
      rescue StandardError
        false
      end

      private

      def url
        config_serializer["url"]
      end

      def username
        config_serializer["username"]
      end

      def password
        config_serializer["password"]
      end

      def consumer_active?
        consumers = rabbitmq_data["consumer_details"]

        return false unless consumers.is_a?(Array)

        lookup = @consumer_lookup ||= consumers.to_h { |c| [c["consumer_tag"], c["active"]] }

        lookup[@consumer_tag] == true
      end

      def rabbitmq_data
        @rabbitmq_data ||= begin
          uri = URI("#{url}/api/queues/%2F/#{@queue_name}")

          request = Net::HTTP::Get.new(uri)
          request.basic_auth(username, password)
          request["Content-Type"] = "application/json"

          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
            http.request(request)
          end

          JSON.parse(response.body)
        end
      end

      def config_serializer
        @config_serializer ||= Services::YmlSerializer.new.call["rabbitmq"]
      rescue StandardError
        nil
      end
    end
  end
end
