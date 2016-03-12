require "spec_helper"

describe Gitrob::CLI::Commands::AcceptTermsOfUse do
  let(:agreement_file_path) do
    File.expand_path("../../../../../../agreement.txt", __FILE__)
  end

  let(:options) { Hash.new }

  context "when agreement file does not exist" do
    it "outputs license" do
      expect(File)
        .to receive(:exist?)
        .with(agreement_file_path)
        .and_return(false)
      expect_any_instance_of(HighLine)
        .to receive(:agree)
        .with("\n\nDo you agree to the terms of use? (y/n): ")
        .and_return("y")
      allow_any_instance_of(described_class)
        .to receive(:accept_terms_of_use)

      output = capture_stdout do
        described_class.new(options)
      end

      expect(output).to include("The MIT License (MIT)" \
        "\n\nCopyright (c) 2016 Michael Henriksen")
    end

    it "outputs agreement" do
      expect(File)
        .to receive(:exist?)
        .with(agreement_file_path)
        .and_return(false)
      expect_any_instance_of(HighLine)
        .to receive(:agree)
        .with("\n\nDo you agree to the terms of use? (y/n): ")
        .and_return("y")
      allow_any_instance_of(described_class)
        .to receive(:accept_terms_of_use)

      output = capture_stdout do
        described_class.new(options)
      end

      expect(output).to include(
        "Gitrob is designed for security professionals. " \
        "If you use any information\nfound through this " \
        "tool for malicious purposes that are not " \
        "authorized by\nthe target, you are " \
        "violating the terms of use and license of " \
        "this\ntool. By typing y/yes, you agree to the " \
        "terms of use and that you will use\nthis tool " \
        "for lawful purposes only."
      )
    end

    context "when accepting the Terms Of Use" do
      it "creates agreement file" do
        expect(File)
          .to receive(:exist?)
          .with(agreement_file_path)
          .and_return(false)
        expect_any_instance_of(HighLine)
          .to receive(:agree)
          .with("\n\nDo you agree to the terms of use? (y/n): ")
          .and_return("yes")
        spy_file = spy
        expect(File)
          .to receive(:open)
          .with(agreement_file_path, "w")
          .and_yield(spy_file)

        capture_stdout do
          described_class.new(options)
        end

        expect(spy_file).to have_received(:write).with("user accepted")
      end
    end

    context "when not accepting the Terms Of Use" do
      it "does not create agreement file" do
        expect(File)
          .to receive(:exist?)
          .with(agreement_file_path)
          .and_return(false)
        expect_any_instance_of(HighLine)
          .to receive(:agree)
          .with("\n\nDo you agree to the terms of use? (y/n): ")
          .and_return(false)
        expect_any_instance_of(described_class)
          .to receive(:fatal)
          .with("Exiting Gitrob.")
        expect(File)
          .not_to receive(:open)
          .with(agreement_file_path, "w")

        capture_stdout do
          described_class.new(options)
        end
      end
    end
  end

  context "when agreement file exists" do
    it "does not display Terms Of Use" do
      expect(File)
        .to receive(:exist?)
        .with(agreement_file_path)
        .and_return(true)

      output = capture_stdout do
        described_class.new(options)
      end

      expect(output).to be_empty
    end

    it "does not ask for agreement" do
      expect(File)
        .to receive(:exist?)
        .with(agreement_file_path)
        .and_return(true)
      expect_any_instance_of(HighLine)
        .not_to receive(:agree)
        .with("\n\nDo you agree to the terms of use? (y/n): ")

      capture_stdout do
        described_class.new(options)
      end
    end
  end
end
