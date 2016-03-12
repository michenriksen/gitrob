require "spec_helper"

describe Gitrob::Github::ClientManager do
  let(:configuration) do
    {
      :endpoint      => "https://api.example.com",
      :site          => "https://example.com",
      :verify_ssl    => true,
      :access_tokens => %w(
        deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
        deadbabedeadbabedeadbabedeadbabedeadbabe
      )
    }
  end

  subject { described_class.new(configuration) }

  it "creates a client for each access token" do
    expect(subject.clients.count).to eq(2)
  end

  describe "Clients" do
    subject { described_class.new(configuration).clients }

    it "is an instance of Github::Client" do
      subject.each do |client|
        expect(client).to be_a(Github::Client)
      end
    end

    it "has access token given in configuration" do
      expect(subject.first.oauth_token)
        .to eq("deadbeefdeadbeefdeadbeefdeadbeefdeadbeef")
      expect(subject.last.oauth_token)
        .to eq("deadbabedeadbabedeadbabedeadbabedeadbabe")
    end

    it "queries endpoint given in configuration" do
      subject.each do |client|
        expect(client.endpoint)
          .to eq("https://api.example.com")
      end
    end

    it "has site given in configuration" do
      subject.each do |client|
        expect(client.site)
          .to eq("https://example.com")
      end
    end

    it "has SSL verification option given in configuration" do
      subject.each do |client|
        expect(client.ssl)
          .to be true
      end
    end

    it "has a Gitrob user-agent" do
      subject.each do |client|
        expect(client.user_agent).to eq("Gitrob v#{Gitrob::VERSION}")
      end
    end
  end

  describe "#sample" do
    it "returns a random client" do
      clients = spy
      expect(clients).to receive(:sample)
      allow(clients).to receive(:count)
        .and_return(1)
      allow(subject).to receive(:clients)
        .and_return(clients)
      subject.sample
    end

    context "when there are no clients" do
      it "raises NoClientsError" do
        expect do
          allow(subject).to receive(:clients)
            .and_return([])
          subject.sample
        end.to raise_error(Gitrob::Github::ClientManager::NoClientsError)
      end
    end
  end

  describe "#remove" do
    it "removes given client from client pool" do
      client = subject.clients.last
      expect(subject.clients.count).to eq(2)
      subject.remove(client)
      expect(subject.clients.count).to eq(1)
      expect(subject.clients.last).to_not eq(client)
    end

    context "when removing a client that is not in client pool" do
      it "does not raise an error" do
        client = subject.clients.last
        subject.remove(client)
        expect do
          subject.remove(client)
        end.to_not raise_error
      end
    end
  end
end
