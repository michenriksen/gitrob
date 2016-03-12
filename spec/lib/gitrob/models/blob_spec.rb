require "spec_helper"

describe Gitrob::Models::Blob do
  subject { build(:blob) }

  describe "Associations" do
    it "has many flags" do
      expect(subject).to respond_to(:flags)
    end

    it "belongs to assessment" do
      expect(subject).to respond_to(:assessment)
    end

    it "belongs to owner" do
      expect(subject).to respond_to(:owner)
    end

    it "belongs to repository" do
      expect(subject).to respond_to(:repository)
    end
  end

  describe "Mass assignment" do
    subject { described_class.allowed_columns }

    describe "Allowed" do
      it "allows path" do
        expect(subject).to include(:path)
      end

      it "allows size" do
        expect(subject).to include(:size)
      end

      it "allows sha" do
        expect(subject).to include(:sha)
      end
    end

    describe "Protected" do
      it "protects assessment_id" do
        expect(subject).to_not include(:assessment_id)
      end

      it "protects repository_id" do
        expect(subject).to_not include(:repository_id)
      end

      it "protects owner_id" do
        expect(subject).to_not include(:owner_id)
      end

      it "protects flags_count" do
        expect(subject).to_not include(:flags_count)
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
    it "validates presence of path" do
      expect(build(:blob, :path => nil)).to_not be_valid
    end

    it "validates presence of size" do
      expect(build(:blob, :size => nil)).to_not be_valid
    end

    it "validates presence of sha" do
      expect(build(:blob, :sha => nil)).to_not be_valid
    end

    it "validates format of sha" do
      %w(lol dfjkhgdfkjgh deadbeef).each do |invalid|
        expect(build(:blob, :sha => invalid)).to_not be_valid
      end
    end
  end

  describe "#path" do
    subject { build(:blob, :path => "/config/database.yml") }

    it "returns full path" do
      expect(subject.path).to eq("/config/database.yml")
    end
  end

  describe "#filename" do
    subject { build(:blob, :path => "/config/database.yml") }

    it "returns file name" do
      expect(subject.filename).to eq("database.yml")
    end
  end

  describe "#extension" do
    subject { build(:blob, :path => "/config/database.yml") }

    it "returns file name" do
      expect(subject.extension).to eq("yml")
    end
  end

  describe "#test_blob?" do
    context "when blob is likely related to testing" do
      it "returns true" do
        %w(
          spec/models/user.rb
          config/test_key.asc
          test/fixtures/users.json
          mock_id_rsa
          stubs/email.rb
          config/fake_otr.private_key
        ).each do |path|
          expect(build(:blob, :path => path).test_blob?).to be true
        end
      end
    end

    context "when blob is not likely related to testing" do
      it "returns false" do
        %w(
          ssh/id_rsa
          home/.bash_history
          lib/models/user.rb
          config/database.yml
          app/controllers/users_controller.rb
          bin/app
        ).each do |path|
          expect(build(:blob, :path => path).test_blob?).to be false
        end
      end
    end
  end
end
