# BunnyKeeper

BunnyKeeper is a Ruby gem for managing RabbitMQ consumers with automatic supervision and health checks. It provides a robust way to monitor and restart failed consumers, ensuring your message processing remains reliable.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bunny_keeper'
```

And then execute:

```bash
$ bundle install
```

## Configuration

Generate the configuration file by running:

```bash
$ rake bunny_keeper_init
```

This will create a `config/bunny_keeper.yml` file with the following structure:

```yaml
name: YourAppName

contexts:
  your_context:
    description: "Description of your queues context"
    queues:
      - queue.name.one
      - queue.name.two
    max_restart: 3

queues:
  queue.name.one:
    description: "Description of what this queue does"
    handler_class: "Your::Handler::Class"
    method: "process"
    parameters: # optional
      key: "value"
  queue.name.two:
    description: "Another queue description"
    handler_class: "Another::Handler::Class"
    method: "start"

logging:
  path: "logs/bunny_keeper.log"
  max_size: 10
  shift_count: 2

notifications: # optional
  discord:
    webhook_url: <%= ENV["DISCORD_WEBHOOK_URL"] %>

rabbitmq:
  url: <%= ENV["RABBITMQ_URL"] %>
  username: <%= ENV["RABBITMQ_USER"] %>
  password: <%= ENV["RABBITMQ_PASSWORD"] %>

heartbeat: 3
```

## Usage

### Starting the Supervisor

In your application, require the gem and start the supervisor:

```ruby
require 'bunny_keeper'

BunnyKeeper::Service.start
```

The supervisor will:
- Start all configured consumers in separate threads
- Monitor consumer health through heartbeat checks
- Automatically restart failed consumers (up to `max_restart` times)
- Gracefully shut down when maximum restarts are reached
- Generate log files at `logs/bunny_keeper.log` with detailed activity information

### Health Checks

You can check if a specific consumer is active using the health check feature:

```ruby
require 'bunny_keeper/services/rabbitmq/consumer_inspect'

# Check if a consumer is active
consumer_active = Services::Rabbitmq::ConsumerInspect.new('queue_name', 'CONSUMER_TAG').exists?
```

This queries the RabbitMQ Management API to verify if the consumer with the specified tag is currently active in the given queue.

### Logging

BunnyKeeper automatically generates log files at the configured path (default: `logs/bunny_keeper.log`). The logs include:

- Consumer startup and initialization
- Health check activities
- Consumer restarts and failures
- Process termination events
- Error details and debugging information

Log rotation is configured through:
- `max_size`: Maximum log file size in MB before rotation
- `shift_count`: Number of backup log files to keep

### Configuration Details

### Contexts
Contexts group related queues together for organized management. Each context can have its own restart limit.

### Queues
Each queue configuration specifies:
- `handler_class`: The Ruby class that processes messages
- `method`: The method to call on the handler class
- `parameters`: Optional parameters passed to the handler method

### RabbitMQ Settings
Configure your RabbitMQ connection using environment variables for security:
- `RABBITMQ_URL`: RabbitMQ server URL
- `RABBITMQ_USER`: Username for authentication
- `RABBITMQ_PASSWORD`: Password for authentication

### Heartbeat
The `heartbeat` setting defines how often (in seconds) the supervisor checks consumer health. Lower values provide faster failure detection but increase system load.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
