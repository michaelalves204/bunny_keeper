# frozen_string_literal: true

require_relative "bunny_keeper/version"
require_relative "bunny_keeper/services/supervisor"
load "tasks/bunny_keeper_init.rake" if defined?(Rake)

module BunnyKeeper
  LOGO = <<~'ASCII'
    $$$$$$$\                                                $$\   $$\
    $$  __$$\                                               $$ | $$  |
    $$ |  $$ |$$\   $$\ $$$$$$$\  $$$$$$$\  $$\   $$\       $$ |$$  / $$$$$$\   $$$$$$\   $$$$$$\   $$$$$$\   $$$$$$\
    $$$$$$$\ |$$ |  $$ |$$  __$$\ $$  __$$\ $$ |  $$ |      $$$$$  / $$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\
    $$  __$$\ $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |      $$  $$<  $$$$$$$$ |$$$$$$$$ |$$ /  $$ |$$$$$$$$ |$$ |  \__|
    $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |      $$ |\$$\ $$   ____|$$   ____|$$ |  $$ |$$   ____|$$ |
    $$$$$$$  |\$$$$$$  |$$ |  $$ |$$ |  $$ |\$$$$$$$ |      $$ | \$$\\$$$$$$$\ \$$$$$$$\ $$$$$$$  |\$$$$$$$\ $$ |
    \_______/  \______/ \__|  \__|\__|  \__| \____$$ |      \__|  \__|\_______| \_______|$$  ____/  \_______|\__|
                                            $$\   $$ |                                   $$ |
                                            \$$$$$$  |                                   $$ |
                                             \______/                                    \__|
  ASCII

  class Error < StandardError; end

  # The TaskExecutor class is responsible for executing arbitrary service classes
  # dynamically. It receives the class name as a string, instantiates it, and
  # runs the configured method with the provided arguments. This component acts
  # as the core execution engine for BunnyKeeper, enabling consumers, loggers,
  # and webhook dispatchers to be triggered in a uniform and flexible way.
  class Service
    def self.start
      puts LOGO

      Services::Supervisor.new.call
    end
  end

  # Error generated when the configuration file is not found.
  class ConfigFileNotFound < StandardError
    def initialize(msg = nil)
      super("Configuration file not found #{msg}")
    end
  end

  # Error generated when the contents of the configuration file are invalid.
  class ConfigInvalidContent < StandardError
    def initialize(msg = nil)
      super("Invalid configuration file content #{msg}")
    end
  end

  # Error occurred when queue not found.
  class QueueNotFound < StandardError
    def initialize(msg = nil)
      super("There are no queues for the context. #{msg}")
    end
  end

  # Error occurred when the queue does not have a filled context.
  class ContextNotFound < StandardError
    def initialize(msg = nil)
      super("There are no queues for the context. #{msg}")
    end
  end

  # Error occurred when the queue does not have a filled handler class.
  class ConfigHandlerClassNotFound < StandardError
    def initialize(msg = nil)
      super("Class not found for #{msg} queue.")
    end
  end

  # Error occurred when the queue does not have a filled method.
  class ConfigMethodNotFound < StandardError
    def initialize(msg = nil)
      super("Mehotd not found for #{msg} queue.")
    end
  end

  # Error occurred when the handler class is not executed.
  class ClassNotPerformed < StandardError
    def initialize(msg = nil)
      super("The class could not be executed - #{msg}")
    end
  end
end
