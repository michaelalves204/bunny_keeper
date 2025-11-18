# frozen_string_literal: true

require_relative "../../bunny_keeper"

module Services
  # This class is responsible for receiving a class name (as string),
  # instantiating it, and executing a specific method with optional arguments.
  # It is used as a generic executor for background tasks, consumers,
  # webhook senders, and other dynamic service classes inside the gem.
  class TaskExecutor
    def initialize(class_name:, method_name:, args: [])
      @class_name = class_name
      @method_name = method_name
      @args = args
    end

    def call!
      klass = Object.const_get(@class_name)
      instance = klass.is_a?(Class) ? klass.new : klass
      instance.public_send(@method_name, *@args)
    rescue StandardError => e
      raise BunnyKeeper::ClassNotPerformed.new(
        { class_name: @class_name, method: @method_name, args: @args, error: e.message }
      )
    end
  end
end
