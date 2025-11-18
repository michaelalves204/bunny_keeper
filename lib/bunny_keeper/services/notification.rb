# frozen_string_literal: true

require_relative "../discord_webhook_service"

module Services
  # Sends restart notifications to a Discord webhook with project metadata.
  class Notification
    TITLE = "Process restarting"

    def initialize(config_hash, contexts, restarts)
      @config_hash = config_hash
      @contexts = contexts
      @restarts = restarts
    end

    def call
      return unless webhook_url

      DiscordWebhookService.new(webhook_url: webhook_url)
                           .send_embed(title: TITLE, data: data)
    rescue StandardError
      nil
    end

    private

    def data
      {
        project: project_name,
        contexts: @contexts,
        restarts: @restarts,
        datetime: Time.now
      }
    end

    def project_name
      @config_hash&.dig("name")
    end

    def webhook_url
      @config_hash&.dig("notifications", "discord", "webhook_url")
    end
  end
end
