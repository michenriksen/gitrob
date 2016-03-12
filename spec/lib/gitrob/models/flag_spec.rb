require "spec_helper"

describe Gitrob::Models::Flag do
  subject { build(:flag) }

  describe "Associations" do
    it "belongs to assessment" do
      expect(subject).to respond_to(:assessment)
    end

    it "belongs to blob" do
      expect(subject).to respond_to(:blob)
    end
  end

  describe "Mass assignment" do
    subject { described_class.allowed_columns }

    describe "Allowed" do
      it "allows caption" do
        expect(subject).to include(:caption)
      end

      it "allows description" do
        expect(subject).to include(:description)
      end
    end

    describe "Protected" do
      it "protects assessment_id" do
        expect(subject).to_not include(:assessment_id)
      end

      it "protects repository_id" do
        expect(subject).to_not include(:repository_id)
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
    it "validates presence of caption" do
      expect(build(:flag, :caption => nil)).to_not be_valid
    end
  end
end
