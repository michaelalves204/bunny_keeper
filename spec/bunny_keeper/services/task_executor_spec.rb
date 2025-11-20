# frozen_string_literal: true

require "spec_helper"

RSpec.describe Services::TaskExecutor do
  describe "#call!" do
    context "when class and method exist" do
      let(:test_class) do
        Class.new do
          def test_method(arg1, arg2)
            "result: #{arg1} #{arg2}"
          end
        end
      end

      before do
        stub_const("TestClass", test_class)
      end

      it "executes the method successfully" do
        executor = described_class.new(
          class_name: "TestClass",
          method_name: "test_method",
          args: %w[hello world]
        )

        result = executor.call!

        expect(result).to eq("result: hello world")
      end
    end

    context "when class is a module with singleton methods" do
      let(:test_module) do
        Module.new do
          def self.singleton_method(arg)
            "singleton: #{arg}"
          end
        end
      end

      before do
        stub_const("TestModule", test_module)
      end

      it "executes the singleton method successfully" do
        executor = described_class.new(
          class_name: "TestModule",
          method_name: "singleton_method",
          args: ["test"]
        )

        result = executor.call!

        expect(result).to eq("singleton: test")
      end
    end

    context "when class does not exist" do
      it "raises ClassNotPerformed error" do
        executor = described_class.new(
          class_name: "NonExistentClass",
          method_name: "some_method"
        )

        expect { executor.call! }.to raise_error(BunnyKeeper::ClassNotPerformed)
      end
    end

    context "when method does not exist" do
      before do
        stub_const("TestClass", Class.new)
      end

      it "raises ClassNotPerformed error" do
        executor = described_class.new(
          class_name: "TestClass",
          method_name: "non_existent_method"
        )

        expect { executor.call! }.to raise_error(BunnyKeeper::ClassNotPerformed)
      end
    end

    context "when method raises an error" do
      let(:error_class) do
        Class.new do
          def failing_method
            raise StandardError, "something went wrong"
          end
        end
      end

      before do
        stub_const("ErrorClass", error_class)
      end

      it "raises ClassNotPerformed error with original error details" do
        executor = described_class.new(
          class_name: "ErrorClass",
          method_name: "failing_method"
        )

        expect { executor.call! }.to raise_error(BunnyKeeper::ClassNotPerformed)
      end
    end

    context "when no arguments are provided" do
      let(:simple_class) do
        Class.new do
          def no_args_method
            "no args result"
          end
        end
      end

      before do
        stub_const("SimpleClass", simple_class)
      end

      it "executes method without arguments" do
        executor = described_class.new(
          class_name: "SimpleClass",
          method_name: "no_args_method",
          args: []
        )

        result = executor.call!

        expect(result).to eq("no args result")
      end
    end
  end
end
