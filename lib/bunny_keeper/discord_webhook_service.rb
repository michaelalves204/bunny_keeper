# frozen_string_literal: true

require "net/http"
require "json"
require "uri"
# Service responsible for sending messages to a Discord Webhook.
class DiscordWebhookService
  def initialize(webhook_url:)
    @webhook_url = webhook_url
  end

  def send_embed(title:, data:, color: 15_158_332)
    uri = URI.parse(@webhook_url)

    fields = data.map { |key, value| { name: key.to_s, value: value.to_s, inline: false } }

    request = Net::HTTP::Post.new(uri, { "Content-Type": "application/json" })
    request.body = payload(title, color, fields)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = http.request(request)

    response.is_a?(Net::HTTPSuccess)
  rescue StandardError
    nil
  end

  def payload(title, color, fields)
    {
      content: "**#{title}**",
      embeds: [
        {
          color: color,
          fields: fields
        }
      ]
    }.to_json
  end
end
