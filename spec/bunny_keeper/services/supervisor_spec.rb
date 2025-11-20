# frozen_string_literal: true

require "spec_helper"

RSpec.describe Services::Supervisor do
  let(:supervisor) { described_class.new }
  let(:mock_config) do
    {
      "contexts" => {
        "default" => {
          "queues" => ["queue1", "queue2"]
        }
      },
      "queues" => {
        "queue1" => { "name" => "queue1" },
        "queue2" => { "name" => "queue2" }
      },
      "heartbeat" => 1,
      "max_restarts" => 2,
      "logging" => {
        "max_size" => 10,
        "shift_count" => 5,
        "path" => "/tmp/test.log"
      }
    }
  end

  before do
    allow_any_instance_of(Services::YmlSerializer).to receive(:call).and_return(mock_config)
    allow(Services::ConcurrencyConsumer).to receive(:new).and_return(double(call: true))
    allow(Services::ConcurrencyConsumer::CONSUMERS).to receive(:each)
    allow(LoggerService).to receive(:new).and_return(double(info: true, warn: true))
  end

  describe "#call" do
    it "executes consumers and starts supervision loop" do
      expect(supervisor).to receive(:execute_consumers)
      expect(supervisor).to receive(:loop).and_yield

      supervisor.call
    end
  end

  describe "private methods" do
    describe "#execute_consumers" do
      it "creates consumers for each queue in contexts" do
        expect(supervisor).to receive(:create_consumer).with("queue1")
        expect(supervisor).to receive(:create_consumer).with("queue2")

        supervisor.send(:execute_consumers)
      end

      it "raises QueueNotFound when queues are missing for context" do
        allow(mock_config).to receive(:dig).with("contexts", "default", "queues").and_return(nil)

        expect { supervisor.send(:execute_consumers) }.to raise_error(BunnyKeeper::QueueNotFound)
      end
    end

    describe "#create_consumer" do
      it "creates a concurrency consumer for the queue" do
        expect(Services::ConcurrencyConsumer).to receive(:new).with(
          consumer: { "name" => "queue1" },
          queue_name: "queue1",
          logger: anything
        )

        supervisor.send(:create_consumer, "queue1")
      end

      it "raises QueueNotFound when queues config is missing" do
        allow(mock_config).to receive(:[]).with("queues").and_return(nil)

        expect { supervisor.send(:create_consumer, "queue1") }.to raise_error(BunnyKeeper::QueueNotFound)
      end
    end

    describe "#contexts" do
      it "returns context keys" do
        expect(supervisor.send(:contexts)).to eq(["default"])
      end

      it "raises ContextNotFound when contexts are missing" do
        allow(mock_config).to receive(:[]).with("contexts").and_return(nil)

        expect { supervisor.send(:contexts) }.to raise_error(BunnyKeeper::ContextNotFound)
      end
    end

    describe "#heartbeat" do
      it "returns configured heartbeat" do
        expect(supervisor.send(:heartbeat)).to eq(1)
      end

      it "returns default heartbeat when not configured" do
        allow(mock_config).to receive(:[]).with("heartbeat").and_return(nil)

        expect(supervisor.send(:heartbeat)).to eq(5)
      end
    end

    describe "#max_restarts" do
      it "returns configured max_restarts" do
        expect(supervisor.send(:max_restarts)).to eq(2)
      end

      it "returns default max_restarts when not configured" do
        allow(mock_config).to receive(:[]).with("max_restarts").and_return(nil)

        expect(supervisor.send(:max_restarts)).to eq(3)
      end
    end

    describe "#restart_consumer" do
      it "increments restarts and creates consumer" do
        expect(supervisor).to receive(:create_consumer).with("queue1")

        supervisor.send(:restart_consumer, "queue1")

        expect(supervisor.instance_variable_get(:@restarts)).to eq(1)
      end
    end

    describe "#close_process" do
      it "sends notification and exits" do
        expect(Services::Notification).to receive(:new).and_return(double(call: true))
        expect(supervisor.send(:logger_service)).to receive(:info)
        expect(supervisor).to receive(:exit)

        supervisor.send(:close_process)
      end
    end
  end
end
