require "spec_helper"

describe Gitrob::CLI::ProgressBar do
  def stub_progress_bar
    allow(ProgressBar).to receive(:create)
  end

  let(:message) { "test" }

  describe "Initializer" do
    let(:default_options) do
      {
        :format =>
          "#{'[*]'.light_blue} %t %c/%C %B %j% %e",
        :progress_mark => "|".light_blue,
        :remainder_mark => "|"
      }
    end

    it "creates a progress bar with default options" do
      expect(ProgressBar)
        .to receive(:create)
        .with(default_options)
      capture_stdout do
        described_class.new(message)
      end
    end

    it "prints message as an informational message" do
      stub_progress_bar
      expect(Gitrob::CLI)
        .to receive(:info)
        .with(message)
      capture_stdout do
        described_class.new(message)
      end
    end

    context "when given options" do
      it "overwrites default options" do
        expected_options = default_options.merge(
          :format => nil
        )
        expect(ProgressBar)
          .to receive(:create)
          .with(expected_options)
        capture_stdout do
          described_class.new(message, expected_options)
        end
      end
    end
  end

  describe "#finish" do
    it "calls #finish on internal progress bar" do
      stub_progress_bar
      spy_progress_bar = spy
      expect(spy_progress_bar)
        .to receive(:finish)
      allow_any_instance_of(described_class)
        .to receive(:progress_bar)
        .and_return(spy_progress_bar)
      capture_stdout do
        described_class.new(message).finish
      end
    end
  end

  describe "#info" do
    it "calls #log on internal progress bar" do
      stub_progress_bar
      spy_progress_bar = spy
      expect(spy_progress_bar)
        .to receive(:log)
        .with("#{'[+]'.light_blue} Info message")
      allow_any_instance_of(described_class)
        .to receive(:progress_bar)
        .and_return(spy_progress_bar)
      capture_stdout do
        described_class.new(message).info("Info message")
      end
    end
  end

  describe "#warn" do
    it "calls #log on internal progress bar" do
      stub_progress_bar
      spy_progress_bar = spy
      expect(spy_progress_bar)
        .to receive(:log)
        .with("#{'[!]'.light_yellow} Warning message")
      allow_any_instance_of(described_class)
        .to receive(:progress_bar)
        .and_return(spy_progress_bar)
      capture_stdout do
        described_class.new(message).warn("Warning message")
      end
    end
  end

  describe "#error" do
    it "calls #log on internal progress bar" do
      stub_progress_bar
      spy_progress_bar = spy
      expect(spy_progress_bar)
        .to receive(:log)
        .with("#{'[!]'.light_red} Error message")
      allow_any_instance_of(described_class)
        .to receive(:progress_bar)
        .and_return(spy_progress_bar)
      capture_stdout do
        described_class.new(message).error("Error message")
      end
    end
  end

  context "When unknown method is missing" do
    context "when internal progress bar responds to method" do
      it "calls method on internal progress bar" do
        stub_progress_bar
        spy_progress_bar = spy
        expect(spy_progress_bar)
          .to receive(:meta_method)
          .with("test")
        allow_any_instance_of(described_class)
          .to receive(:progress_bar)
          .and_return(spy_progress_bar)
        capture_stdout do
          described_class.new(message).meta_method("test")
        end
      end
    end

    context "when internal progress bar does not respond to method" do
      it "raises NoMethodError exception" do
        stub_progress_bar
        expect do
          capture_stdout do
            described_class.new(message).meta_method
          end
        end.to raise_error(NoMethodError)
      end
    end
  end
end
