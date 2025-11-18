# frozen_string_literal: true

require "yaml"
require "erb"
require_relative "../../bunny_keeper"

module Services
  # Reads and returns the contents of the configuration file in hash format.
  class YmlSerializer
    CONFIG_PATH = File.join(Dir.pwd, "config/bunny_keeper.yml")

    def call
      raise BunnyKeeper::ConfigFileNotFound unless File.exist?(CONFIG_PATH)

      content = ERB.new(File.read(CONFIG_PATH)).result
      yml_content = YAML.safe_load(content, aliases: true)

      raise BunnyKeeper::ConfigInvalidContent unless yml_content.is_a?(Hash)

      yml_content
    rescue Psych::SyntaxError => e
      raise BunnyKeeper::ConfigInvalidContent, e.message
    end
  end
end
