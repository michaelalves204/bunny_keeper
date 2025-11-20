# frozen_string_literal: true

require "spec_helper"
require "bunny_keeper/services/rabbitmq/consumer_inspect"

RSpec.describe Services::Rabbitmq::ConsumerInspect do
  let(:queue_name) { "test_queue" }
  let(:consumer_tag) { "test_consumer" }
  let(:consumer_inspect) { described_class.new(queue_name, consumer_tag) }

  before do
    allow_any_instance_of(Services::YmlSerializer).to receive(:call).and_return(
      "rabbitmq" => {
        "url" => "http://localhost:15672",
        "username" => "guest",
        "password" => "guest"
      }
    )
  end

  describe "#exists?" do
    context "when consumer is active" do
      before do
        mock_response = {
          "consumer_details" => [
            { "consumer_tag" => consumer_tag, "active" => true },
            { "consumer_tag" => "other_consumer", "active" => false }
          ]
        }

        allow(Net::HTTP).to receive(:start).and_return(double(body: mock_response.to_json))
      end

      it "returns true" do
        expect(consumer_inspect.exists?).to be true
      end
    end

    context "when consumer is not active" do
      before do
        mock_response = {
          "consumer_details" => [
            { "consumer_tag" => consumer_tag, "active" => false },
            { "consumer_tag" => "other_consumer", "active" => true }
          ]
        }

        allow(Net::HTTP).to receive(:start).and_return(double(body: mock_response.to_json))
      end

      it "returns false" do
        expect(consumer_inspect.exists?).to be false
      end
    end

    context "when consumer is not found" do
      before do
        mock_response = {
          "consumer_details" => [
            { "consumer_tag" => "other_consumer", "active" => true }
          ]
        }

        allow(Net::HTTP).to receive(:start).and_return(double(body: mock_response.to_json))
      end

      it "returns false" do
        expect(consumer_inspect.exists?).to be false
      end
    end

    context "when consumer_details is not an array" do
      before do
        mock_response = { "consumer_details" => "invalid" }

        allow(Net::HTTP).to receive(:start).and_return(double(body: mock_response.to_json))
      end

      it "returns false" do
        expect(consumer_inspect.exists?).to be false
      end
    end

    context "when RabbitMQ API returns error" do
      before do
        allow(Net::HTTP).to receive(:start).and_raise(StandardError, "API error")
      end

      it "returns false" do
        expect(consumer_inspect.exists?).to be false
      end
    end

    context "when config serializer fails" do
      before do
        allow_any_instance_of(Services::YmlSerializer).to receive(:call).and_raise(StandardError)
      end

      it "returns false" do
        expect(consumer_inspect.exists?).to be false
      end
    end

    context "when rabbitmq config is missing" do
      before do
        allow_any_instance_of(Services::YmlSerializer).to receive(:call).and_return({})
      end

      it "returns false" do
        expect(consumer_inspect.exists?).to be false
      end
    end
  end

  describe "private methods" do
    describe "#url" do
      it "returns rabbitmq url from config" do
        expect(consumer_inspect.send(:url)).to eq("http://localhost:15672")
      end
    end

    describe "#username" do
      it "returns rabbitmq username from config" do
        expect(consumer_inspect.send(:username)).to eq("guest")
      end
    end

    describe "#password" do
      it "returns rabbitmq password from config" do
        expect(consumer_inspect.send(:password)).to eq("guest")
      end
    end

    describe "#config_serializer" do
      it "returns rabbitmq config from yml serializer" do
        expect(consumer_inspect.send(:config_serializer)).to eq(
          "url" => "http://localhost:15672",
          "username" => "guest",
          "password" => "guest"
        )
      end

      it "returns nil when serializer fails" do
        allow_any_instance_of(Services::YmlSerializer).to receive(:call).and_raise(StandardError)

        expect(consumer_inspect.send(:config_serializer)).to be_nil
      end
    end

    describe "#consumer_active?" do
      before do
        mock_response = {
          "consumer_details" => [
            { "consumer_tag" => consumer_tag, "active" => true },
            { "consumer_tag" => "other_consumer", "active" => false }
          ]
        }

        allow(Net::HTTP).to receive(:start).and_return(double(body: mock_response.to_json))
      end

      it "returns true for active consumer" do
        expect(consumer_inspect.send(:consumer_active?)).to be true
      end

      it "caches the consumer lookup" do
        consumer_inspect.send(:consumer_active?)
        lookup = consumer_inspect.instance_variable_get(:@consumer_lookup)

        expect(lookup).to eq(
          consumer_tag => true,
          "other_consumer" => false
        )
      end
    end
  end
end
