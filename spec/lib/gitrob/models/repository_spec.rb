require "spec_helper"

describe Gitrob::Models::Repository do
  subject { build(:repository) }

  describe "Associations" do
    it "has many blobs" do
      expect(subject).to respond_to(:blobs)
    end

    it "belongs to owner" do
      expect(subject).to respond_to(:owner)
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

      it "allows name" do
        expect(subject).to include(:name)
      end

      it "allows full_name" do
        expect(subject).to include(:full_name)
      end

      it "allows description" do
        expect(subject).to include(:description)
      end

      it "allows private" do
        expect(subject).to include(:private)
      end

      it "allows url" do
        expect(subject).to include(:url)
      end

      it "allows html_url" do
        expect(subject).to include(:html_url)
      end

      it "allows homepage" do
        expect(subject).to include(:homepage)
      end

      it "allows size" do
        expect(subject).to include(:size)
      end

      it "allows default_branch" do
        expect(subject).to include(:default_branch)
      end
    end

    describe "Protected" do
      it "protects assessment_id" do
        expect(subject).to_not include(:assessment_id)
      end

      it "protects owner_id" do
        expect(subject).to_not include(:owner_id)
      end

      it "protects blobs_count" do
        expect(subject).to_not include(:blobs_count)
      end

      it "protects findings_count" do
        expect(subject).to_not include(:findings_count)
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
      expect(build(:repository, :github_id => nil)).to_not be_valid
    end

    it "validates presence of name" do
      expect(build(:repository, :name => nil)).to_not be_valid
    end

    it "validates presence of full_name" do
      expect(build(:repository, :full_name => nil)).to_not be_valid
    end

    it "validates presence of private" do
      expect(build(:repository, :private => nil)).to_not be_valid
    end

    it "validates presence of url" do
      expect(build(:repository, :url => nil)).to_not be_valid
    end

    it "validates presence of html_url" do
      expect(build(:repository, :html_url => nil)).to_not be_valid
    end

    it "validates presence of size" do
      expect(build(:repository, :size => nil)).to_not be_valid
    end

    it "validates presence of default_branch" do
      expect(build(:repository, :default_branch => nil)).to_not be_valid
    end
  end
end
