require "spec_helper"

describe Gitrob::Models::Owner do
  subject { build(:user) }

  describe "Associations" do
    it "has many repositories" do
      expect(subject).to respond_to(:repositories)
    end

    it "has many blobs" do
      expect(subject).to respond_to(:blobs)
    end

    it "belongs to assessment" do
      expect(subject).to respond_to(:assessment)
    end
  end

  describe "Mass assignment" do
    subject { described_class.allowed_columns }

    describe "Allowed" do
      it "allows github_id" do
        expect(subject).to include(:github_id)
      end

      it "allows login" do
        expect(subject).to include(:login)
      end

      it "allows type" do
        expect(subject).to include(:type)
      end

      it "allows url" do
        expect(subject).to include(:url)
      end

      it "allows html_url" do
        expect(subject).to include(:html_url)
      end

      it "allows avatar_url" do
        expect(subject).to include(:avatar_url)
      end

      it "allows name" do
        expect(subject).to include(:name)
      end

      it "allows blog" do
        expect(subject).to include(:blog)
      end

      it "allows location" do
        expect(subject).to include(:location)
      end

      it "allows email" do
        expect(subject).to include(:email)
      end

      it "allows bio" do
        expect(subject).to include(:bio)
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
    it "validates presence of github_id" do
      expect(build(:user, :github_id => nil)).to_not be_valid
    end

    it "validates presence of login" do
      expect(build(:user, :login => nil)).to_not be_valid
    end

    it "validates presence of type" do
      expect(build(:user, :type => nil)).to_not be_valid
    end

    it "validates presence of url" do
      expect(build(:user, :url => nil)).to_not be_valid
    end

    it "validates presence of html_url" do
      expect(build(:user, :html_url => nil)).to_not be_valid
    end

    it "validates presence of avatar_url" do
      expect(build(:user, :avatar_url => nil)).to_not be_valid
    end

    it "validates that type can only be User or Organization" do
      expect(build(:user, :type => "User")).to be_valid
      expect(build(:user, :type => "Organization")).to be_valid
      expect(build(:user, :type => "Hacker")).to_not be_valid
    end
  end
end
