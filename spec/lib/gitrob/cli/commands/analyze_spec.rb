require "spec_helper"

describe Gitrob::CLI::Commands::Analyze do
  describe "Initializer" do
    let(:options) do
      {
        :endpoint   => "https://api.github.com/",
        :site       => "https://github.com/",
        :verify_ssl => true
      }
    end
    let(:target) { "acme" }

    it "loads signatures" do
      stub_db_assessment = spy
      allow(stub_db_assessment)
        .to receive(:save)
      allow_any_instance_of(described_class)
        .to receive(:gather_owners)
      allow_any_instance_of(described_class)
        .to receive(:gather_repositories)
      allow(Gitrob::Models::Assessment)
        .to receive(:create)
        .and_return(stub_db_assessment)
      allow_any_instance_of(described_class)
        .to receive(:analyze_repositories)
      allow(Gitrob::CLI)
        .to receive(:configuration)
        .and_return(
          "github_access_tokens" => %w(
            deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
            deadbabedeadbabedeadbabedeadbabedeadbabe
          )
        )

      expect_any_instance_of(described_class)
        .to receive(:task)
        .with("Loading signatures...", true)
        .and_yield
      expect(Gitrob::BlobObserver).to receive(:load_signatures!)
      described_class.new(target, options)
    end

    it "gathers owners" do
      stub_db_assessment = spy
      allow(stub_db_assessment)
        .to receive(:save)
      allow_any_instance_of(described_class)
        .to receive(:load_signatures!)
      allow_any_instance_of(described_class)
        .to receive(:gather_repositories)
      allow(Gitrob::Models::Assessment)
        .to receive(:create)
        .and_return(stub_db_assessment)
      allow_any_instance_of(described_class)
        .to receive(:analyze_repositories)
      allow_any_instance_of(described_class)
        .to receive(:owner_count)
        .and_return(1)
      allow(Gitrob::CLI)
        .to receive(:configuration)
        .and_return(
          "github_access_tokens" => %w(
            deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
            deadbabedeadbabedeadbabedeadbabedeadbabe
          )
        )

      expect_any_instance_of(described_class)
        .to receive(:task)
        .with("Gathering targets...")
        .and_yield
      expect_any_instance_of(Gitrob::Github::DataManager)
        .to receive(:gather_owners)
      described_class.new(target, options)
    end

    context "when no owners are returned" do
      it "exits with a fatal error" do
        stub_db_assessment = spy
        allow(stub_db_assessment)
          .to receive(:save)
        allow_any_instance_of(described_class)
          .to receive(:load_signatures!)
        allow_any_instance_of(described_class)
          .to receive(:gather_repositories)
        allow(Gitrob::Models::Assessment)
          .to receive(:create)
          .and_return(stub_db_assessment)
        allow_any_instance_of(described_class)
          .to receive(:analyze_repositories)
        allow(Gitrob::CLI)
          .to receive(:configuration)
          .and_return(
            "github_access_tokens" => %w(
              deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
              deadbabedeadbabedeadbabedeadbabedeadbabe
            )
          )
        allow_any_instance_of(Gitrob::Github::DataManager)
          .to receive(:owners)
          .and_return([])
        expect(Gitrob::CLI)
          .to receive(:fatal)
          .with("No users or organizations found; exiting")

        capture_stdout do
          described_class.new(target, options)
        end
      end
    end

    it "gathers repositories" do
      stub_db_assessment = spy
      allow(stub_db_assessment)
        .to receive(:save)
      allow_any_instance_of(described_class)
        .to receive(:load_signatures!)
      allow(Gitrob::Models::Assessment)
        .to receive(:create)
        .and_return(stub_db_assessment)
      allow_any_instance_of(described_class)
        .to receive(:analyze_repositories)
      allow_any_instance_of(described_class)
        .to receive(:owner_count)
        .and_return(1)
      allow_any_instance_of(described_class)
        .to receive(:repo_count)
        .and_return(1)
      allow(Gitrob::CLI)
        .to receive(:configuration)
        .and_return(
          "github_access_tokens" => %w(
            deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
            deadbabedeadbabedeadbabedeadbabedeadbabe
          )
        )

      expect_any_instance_of(Gitrob::Github::DataManager)
        .to receive(:gather_repositories)
      capture_stdout do
        described_class.new(target, options)
      end
    end
  end
end
