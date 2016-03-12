require "spec_helper"

describe Gitrob::Models::GithubAccessToken do
  subject { build(:github_access_token) }

  describe "Associations" do
    it "belongs to assessment" do
      expect(subject).to respond_to(:assessment)
    end
  end

  describe "Mass assignment" do
    subject { described_class.allowed_columns }

    describe "Allowed" do
      it "allows token" do
        expect(subject).to include(:token)
      end
    end

    describe "Protected" do
      it "protects assessment_id" do
        expect(subject).to_not include(:assessment_id)
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
    it "validates presence of token" do
      expect(build(:github_access_token, :token => nil)).to_not be_valid
    end

    it "validates format of token" do
      %w(lol dfjkhgdfkjgh deadbeef).each do |invalid|
        expect(build(:github_access_token, :token => invalid)).to_not be_valid
      end
    end
  end
end
