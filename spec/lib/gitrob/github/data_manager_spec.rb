require "spec_helper"

describe Gitrob::Github::ClientManager do
  let(:configuration) do
    {
      :endpoint      => "https://api.github.com",
      :site          => "https://github.com",
      :verify_ssl    => false,
      :access_tokens => %w(
        deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
        deadbabedeadbabedeadbabedeadbabedeadbabe
      )
    }
  end

  let(:client_manager) do
    Gitrob::Github::ClientManager.new(configuration)
  end

  let(:thread_pool) do
    FakeThreadPool.new
  end

  subject do
    Gitrob::Github::DataManager.new(%w(acme), client_manager)
  end

  describe "#gather_owners" do
    it "gathers organization and its members" do
      subject.gather_owners(thread_pool)
      expect(subject.owners.count).to eq(3)
      expect(subject.owners[0][:login]).to eq("acme")
      expect(subject.owners[1][:login]).to eq("user1")
      expect(subject.owners[2][:login]).to eq("user2")
    end

    context "when given an owner that doesn't exist" do
      it "adds it to unknown logins" do
        manager = Gitrob::Github::DataManager.new(
          %w(acme notfound),
          client_manager
        )
        manager.gather_owners(thread_pool)
        expect(manager.owners.count).to eq(3)
        expect(manager.unknown_logins).to eq(%w(notfound))
      end
    end

    context "when a GitHub client is unauthorized" do
      it "removes the client" do
        expect(client_manager)
          .to receive(:remove)
          .with(an_instance_of(::Github::Client))
        manager = Gitrob::Github::DataManager.new(
          %w(unauthorized),
          client_manager
        )
        manager.gather_owners(thread_pool)
      end
    end

    context "when a GitHub client is rate limited" do
      it "removes the client" do
        expect(client_manager)
          .to receive(:remove)
          .with(an_instance_of(::Github::Client))
        manager = Gitrob::Github::DataManager.new(
          %w(ratelimited),
          client_manager
        )
        manager.gather_owners(thread_pool)
      end
    end
  end

  describe "#gather_repositories" do
    it "gathers repositories from organization and its members" do
      subject.gather_owners(thread_pool)
      subject.gather_repositories(thread_pool)
      expect(subject.repositories.count).to eq(3)
      expect(subject.repositories[0][:full_name]).to eq("acme/Hello-World")
      expect(subject.repositories[1][:full_name]).to eq("user1/dotfiles")
      expect(subject.repositories[2][:full_name]).to eq("user2/dotfiles")
    end

    it "does not include forked repositories" do
      subject.gather_owners(thread_pool)
      subject.gather_repositories(thread_pool)
      subject.repositories.each do |repo|
        expect(repo[:fork]).to be false
      end
    end

    context "when a block is given" do
      it "yields control for each repository" do
        subject.gather_owners(thread_pool)
        expect do |b|
          subject.gather_repositories(thread_pool, &b)
        end.to yield_control.exactly(3).times
      end

      it "yields control with owner and repositories as arguments" do
        subject.gather_owners(thread_pool)
        subject.gather_repositories(thread_pool) do |owner, repos|
          expect(owner[:login]).to_not be_nil
          expect(repos.count).to eq(1)
          expect(repos.first[:full_name]).to_not be_nil
        end
      end
    end
  end

  describe "#repositories_for_owner" do
    it "returns repositories for owner" do
      subject.gather_owners(thread_pool)
      subject.gather_repositories(thread_pool)
      repos = subject.repositories_for_owner(subject.owners.first)
      expect(repos.count).to eq(1)
      expect(repos.first[:full_name]).to eq("acme/Hello-World")
    end
  end

  describe "#blobs_for_repository" do
    let(:repo) do
      {
        :full_name      => "acme/Hello-World",
        :default_branch => "master"
      }
    end

    let(:blocked_repo) do
      {
        :full_name      => "acme/blocked",
        :default_branch => "master"
      }
    end

    let(:empty_repo) do
      {
        :full_name      => "acme/empty",
        :default_branch => "master"
      }
    end

    let(:notfound_repo) do
      {
        :full_name      => "acme/notfound",
        :default_branch => "master"
      }
    end

    it "returns blobs for a repository" do
      blobs = subject.blobs_for_repository(repo)
      expect(blobs.count).to eq(2)
      expect(blobs[0][:path]).to eq("README.md")
      expect(blobs[1][:path]).to eq("src/helloworld.c")
    end

    context "when repository access is blocked (secret GitHub feature)" do
      it "returns an empty array" do
        expect(subject.blobs_for_repository(blocked_repo)).to eq([])
      end
    end

    context "when repository is empty" do
      it "returns an empty array" do
        expect(subject.blobs_for_repository(empty_repo)).to eq([])
      end
    end

    context "when repository is not found" do
      it "returns an empty array" do
        expect(subject.blobs_for_repository(notfound_repo)).to eq([])
      end
    end
  end
end
