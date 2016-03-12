require "spec_helper"

describe Gitrob::CLI::Command do
  subject { described_class.new }

  describe "Initializer" do
    it "accepts arbitrary amount of arguments" do
      expect do
        described_class.new
        described_class.new(1)
        described_class.new(1, 2)
        described_class.new(1, 2, 3)
        described_class.new(1, 2, 3, 4)
        described_class.new(1, 2, 3, 4, 5)
      end.not_to raise_error
    end

    describe ".start" do
      it "accepts arbitrary amount of arguments" do
        expect do
          described_class.start
          described_class.start(1)
          described_class.start(1, 2)
          described_class.start(1, 2, 3)
          described_class.start(1, 2, 3, 4)
          described_class.start(1, 2, 3, 4, 5)
        end.not_to raise_error
      end

      it "returns an instance of itself" do
        expect(described_class.start).to be_a described_class
      end

      it "passes arbitrary variables to initializer" do
        expect(described_class).to receive(:new)
          .with(1, 2, 3, 4, 5)
        described_class.start(1, 2, 3, 4, 5)
      end
    end

    describe "#info" do
      it "passes message to Gitrob::CLI.info" do
        expect(Gitrob::CLI).to receive(:info)
          .with("This is an informational message")
        subject.info("This is an informational message")
      end
    end

    describe "#task" do
      it "passes message to Gitrob::CLI.task" do
        expect(Gitrob::CLI).to receive(:task)
          .with("This is a task", false)
        subject.task("This is a task")
      end

      it "passes fatal_error to Gitrob::CLI.task" do
        fatal = double("fatal")
        expect(Gitrob::CLI).to receive(:task)
          .with("This is a task", fatal)
        subject.task("This is a task", fatal)
      end

      it "yields to a block" do
        expect do |b|
          capture_stdout do
            subject.task("This is a task", &b)
          end
        end.to yield_control
      end
    end

    describe "#warn" do
      it "passes message to Gitrob::CLI.warn" do
        expect(Gitrob::CLI).to receive(:warn)
          .with("This is a warning message")
        subject.warn("This is a warning message")
      end
    end

    describe "#error" do
      it "passes message to Gitrob::CLI.error" do
        expect(Gitrob::CLI).to receive(:error)
          .with("This is an error message")
        subject.error("This is an error message")
      end
    end

    describe "#fatal" do
      it "passes message to Gitrob::CLI.fatal" do
        expect(Gitrob::CLI).to receive(:fatal)
          .with("Warp Core Breach!")
        subject.fatal("Warp Core Breach!")
      end
    end

    describe "#thread_pool" do
      it "yields to a block with a thread pool" do
        allow(subject).to receive(:options).and_return(
          :threads => 5
        )
        expect do |b|
          subject.thread_pool(&b)
        end.to yield_with_args(an_instance_of(Thread::Pool))
      end
    end

    describe "#progress_bar" do
      it "yields to a block with a progress bar" do
        spy_bar = double("progress_bar")
        allow(spy_bar).to receive(:finish)
        allow(Gitrob::CLI::ProgressBar).to receive(:new).and_return(spy_bar)
        capture_stdout do
          expect do |b|
            subject.progress_bar("testing", {}, &b)
          end.to yield_with_args(spy_bar)
        end
      end
    end
  end
end
