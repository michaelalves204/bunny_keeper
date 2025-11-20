# frozen_string_literal: true

require "spec_helper"
require "tempfile"
# Crie para mim um method de puts

RSpec.describe Services::YmlSerializer do
  let(:serializer) { described_class.new }
  let(:config_path) { described_class::CONFIG_PATH }

  before do
    File.delete(config_path) if File.exist?(config_path)
  end

  after do
    File.delete(config_path) if File.exist?(config_path)
  end

  describe "#call" do
    context "when config file exists and contains valid YAML" do
      let(:valid_yaml_content) do
        <<~YAML
          queues:
            - name: "test_queue"
              context: "test_context"
              handler_class: "TestHandler"
              method: "process"
        YAML
      end

      before do
        File.write(config_path, valid_yaml_content)
      end

      it "returns parsed YAML content as hash" do
        result = serializer.call

        expect(result).to be_a(Hash)
        expect(result["queues"]).to be_an(Array)
        expect(result["queues"].first["name"]).to eq("test_queue")
        expect(result["queues"].first["context"]).to eq("test_context")
        expect(result["queues"].first["handler_class"]).to eq("TestHandler")
        expect(result["queues"].first["method"]).to eq("process")
      end
    end

    context "when config file contains ERB templates" do
      let(:erb_yaml_content) do
        <<~YAML
          queues:
            - name: "test_queue"
              context: "<%= 'test' + '_context' %>"
              handler_class: "TestHandler"
              method: "process"
        YAML
      end

      before do
        File.write(config_path, erb_yaml_content)
      end

      it "processes ERB templates and returns parsed content" do
        result = serializer.call

        expect(result).to be_a(Hash)
        expect(result["queues"].first["context"]).to eq("test_context")
      end
    end

    context "when config file does not exist" do
      it "raises ConfigFileNotFound error" do
        expect { serializer.call }.to raise_error(BunnyKeeper::ConfigFileNotFound)
      end
    end

    context "when config file contains invalid YAML content" do
      let(:invalid_yaml_content) do
        <<~YAML
          - invalid
          - yaml
          - array
        YAML
      end

      before do
        File.write(config_path, invalid_yaml_content)
      end

      it "raises ConfigInvalidContent error" do
        expect { serializer.call }.to raise_error(BunnyKeeper::ConfigInvalidContent)
      end
    end

    context "when config file contains malformed YAML syntax" do
      let(:malformed_yaml_content) do
        <<~YAML
          queues:
            - name: "test_queue
              context: "test_context"
        YAML
      end

      before do
        File.write(config_path, malformed_yaml_content)
      end

      it "raises ConfigInvalidContent error with original message" do
        expect { serializer.call }.to raise_error(BunnyKeeper::ConfigInvalidContent)
      end
    end

    context "when config file contains ERB syntax errors" do
      let(:invalid_erb_content) do
        <<~YAML
          queues:
            - name: "test_queue"
              context: "<%= invalid_ruby_code %>"
        YAML
      end

      before do
        File.write(config_path, invalid_erb_content)
      end

      it "raises NameError for undefined variables in ERB" do
        expect { serializer.call }.to raise_error(NameError)
      end
    end

    context "when config file is empty" do
      before do
        File.write(config_path, "")
      end

      it "raises ConfigInvalidContent error" do
        expect { serializer.call }.to raise_error(BunnyKeeper::ConfigInvalidContent)
      end
    end

    context "when config file contains only whitespace" do
      before do
        File.write(config_path, "   \n  \n  ")
      end

      it "raises ConfigInvalidContent error" do
        expect { serializer.call }.to raise_error(BunnyKeeper::ConfigInvalidContent)
      end
    end
  end

  describe "CONFIG_PATH" do
    it "points to config/bunny_keeper.yml in current directory" do
      expected_path = File.join(Dir.pwd, "config/bunny_keeper.yml")
      expect(described_class::CONFIG_PATH).to eq(expected_path)
    end
  end
end
