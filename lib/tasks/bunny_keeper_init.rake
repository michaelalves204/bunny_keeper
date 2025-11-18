# frozen_string_literal: true

require "fileutils"

YML_CONTENT = <<~YAML
  name: ProjectNameExample

  contexts:
    context_example:
      description: "Context example"
      queues:
        - foo.queue
      max_restart: 3

  queues:
    foo.queue:
      description: "Context example"
      handler_class: "Services::FooQueueHandler"
      method: "call"
      parameters:
        - bars

  logging:
    path: "logs/bunny_keeper.log"
    max_size: 10
    shift_count: 2

  notifications:
    discord:
      webhook_url: <%= ENV["DISCORD_WEBHOOK_URL"] %>

  rabbitmq:
    url: <%= ENV["RABBITMQ_URL"] %>
  heartbeat: 3
YAML

desc "Initializes BunnyKeeper (generates config/bunny_keeper.yml)"
task :bunny_keeper_init do
  config_dir = File.join(Dir.pwd, "config")
  config_file = File.join(config_dir, "bunny_keeper.yml")
  FileUtils.mkdir_p(config_dir)

  if File.exist?(config_file)
    puts "The file #{config_file} already exists. No changes were made."
  else
    File.write(config_file, YML_CONTENT)
    puts "File created successfully in: #{config_file}"
  end
end
