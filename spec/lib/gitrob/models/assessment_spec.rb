require "spec_helper"

describe Gitrob::Models::Assessment do
  subject { build(:assessment) }

  describe "Associations" do
    it "has many GitHub access tokens" do
      expect(subject).to respond_to(:github_access_tokens)
    end

    it "has many owners" do
      expect(subject).to respond_to(:owners)
    end

    it "has many repositories" do
      expect(subject).to respond_to(:repositories)
    end

    it "has many blobs" do
      expect(subject).to respond_to(:blobs)
    end

    it "has many flags" do
      expect(subject).to respond_to(:flags)
    end
  end

  describe "Mass assignment" do
    subject { described_class.allowed_columns }

    describe "Allowed" do
      it "allows name" do
        expect(subject).to include(:name)
      end

      it "allows endpoint" do
        expect(subject).to include(:endpoint)
      end

      it "allows site" do
        expect(subject).to include(:site)
      end

      it "allows verify_ssl" do
        expect(subject).to include(:verify_ssl)
      end
    end

    describe "Protected" do
      it "protects owners_count" do
        expect(subject).to_not include(:owners_count)
      end

      it "protects repositories_count" do
        expect(subject).to_not include(:repositories_count)
      end

      it "protects blobs_count" do
        expect(subject).to_not include(:blobs_count)
      end

      it "protects deleted" do
        expect(subject).to_not include(:deleted)
      end

      it "protects updated_at" do
        expect(subject).to_not include(:updated_at)
      end

      it "protects created_at" do
        expect(subject).to_not include(:created_at)
      end
    end
  end

  describe "Validations" do
    it "validates presence of endpoint" do
      expect(build(:assessment, :endpoint => nil)).to_not be_valid
    end

    it "validates presence of site" do
      expect(build(:assessment, :site => nil)).to_not be_valid
    end

    it "validates presence of verify_ssl" do
      expect(build(:assessment, :verify_ssl => nil)).to_not be_valid
    end
  end

  describe "#save_owner" do
    let(:owner) do
      read_fixture("github/users/user1.json")
    end

    it "creates a new owner model and adds it to assessment model" do
      spy_owner = spy("owner")
      expect(Gitrob::Models::Owner)
        .to receive(:new)
        .with(
          :login => "user1",
          :avatar_url => "https://github.com/images/error/octocat_happy.gif",
          :url => "https://api.github.com/users/user1",
          :html_url => "https://github.com/user1",
          :type => "User",
          :name => "John Doe",
          :blog => "https://user1.com/blog",
          :location => "Berlin",
          :email => "user1@acme.com",
          :bio => "There once was...",
          :github_id => 2
        ).and_return(spy_owner)
      expect(subject).to receive(:add_owner)
        .with(spy_owner)
      subject.save_owner(owner)
    end

    it "increments owners count" do
      allow(subject).to receive(:add_owner)
      expect(subject.owners_count).to eq(0)
      subject.save_owner(owner)
      expect(subject.owners_count).to eq(1)
    end
  end

  describe "#save_repository" do
    let(:repo) do
      read_fixture("github/users/user1/repos.json").first
    end

    let(:owner) do
      build(:user)
    end

    it "creates a new repository model and adds it to assessment model" do
      spy_repo = spy("repo")
      expect(Gitrob::Models::Repository)
        .to receive(:new)
        .with(
          :name => "dotfiles",
          :full_name => "user1/dotfiles",
          :description => "My dotfiles",
          :private => false,
          :url => "https://api.github.com/repos/user1/dotfiles",
          :html_url => "https://github.com/user1/dotfiles",
          :homepage => "https://github.com",
          :size => 2,
          :default_branch => "master",
          :github_id => 1_296_270
        ).and_return(spy_repo)
      expect(subject).to receive(:add_repository)
        .with(spy_repo)
      subject.save_repository(repo, owner)
    end

    it "sets repository's owner to given owner" do
      spy_repo = spy("repo")
      expect(spy_repo).to receive(:owner=)
        .with(owner)
      allow(Gitrob::Models::Repository)
        .to receive(:new)
        .and_return(spy_repo)
      allow(subject).to receive(:add_repository)
      subject.save_repository(spy_repo, owner)
    end

    it "increments repositories count" do
      spy_repo = spy("repo")
      allow(spy_repo).to receive(:owner=)
        .with(owner)
      allow(Gitrob::Models::Repository)
        .to receive(:new)
        .and_return(spy_repo)
      allow(subject).to receive(:add_repository)
      expect(subject.repositories_count).to eq(0)
      subject.save_repository(repo, owner)
      expect(subject.repositories_count).to eq(1)
    end
  end

  describe "#save_blob" do
    let(:blob) do
      read_fixture("github/repos/acme/Hello-World/tree.json")[:tree].first
    end

    let(:repo) do
      build(:repository)
    end

    let(:owner) do
      build(:user)
    end

    it "creates a new blob model and adds it to assessment model" do
      spy_blob = spy("blob")
      expect(Gitrob::Models::Blob)
        .to receive(:new)
        .with(
          :path => "README.md",
          :size => 132,
          :sha => "7c258a9869f33c1e1e1f74fbb32f07c86cb5a75b"
        ).and_return(spy_blob)
      expect(subject).to receive(:add_blob)
        .with(spy_blob)
      subject.save_blob(blob, repo, owner)
    end

    it "sets blob's repository to given repository" do
      spy_blob = spy("blob")
      expect(spy_blob).to receive(:repository=)
        .with(repo)
      allow(Gitrob::Models::Blob)
        .to receive(:new)
        .and_return(spy_blob)
      allow(subject).to receive(:add_blob)
      subject.save_blob(spy_blob, repo, owner)
    end

    it "sets blob's owner to given owner" do
      spy_blob = spy("blob")
      expect(spy_blob).to receive(:owner=)
        .with(owner)
      allow(Gitrob::Models::Blob)
        .to receive(:new)
        .and_return(spy_blob)
      allow(subject).to receive(:add_blob)
      subject.save_blob(spy_blob, repo, owner)
    end

    it "increments blobs count" do
      spy_blob = spy("blob")
      allow(spy_blob).to receive(:repository=)
      allow(spy_blob).to receive(:owner=)
      allow(Gitrob::Models::Blob)
        .to receive(:new)
        .and_return(spy_blob)
      allow(subject).to receive(:add_blob)
      expect(subject.blobs_count).to eq(0)
      subject.save_blob(blob, repo, owner)
      expect(subject.blobs_count).to eq(1)
    end
  end
end
