require "spec_helper"

describe Gitrob::Utils do
  describe ".pluralize" do
    context "when count is zero" do
      it "returns 0 plural" do
        expect(Gitrob::Utils.pluralize(0, "one", "many")).to eq("0 many")
      end
    end

    context "when count is one" do
      it "returns 1 singular" do
        expect(Gitrob::Utils.pluralize(1, "one", "many")).to eq("1 one")
      end
    end

    context "when count is > 1" do
      it "returns plural" do
        [2, 50, 660, 1337].each do |count|
          expect(Gitrob::Utils.pluralize(count, "one", "many"))
            .to eq("#{count} many")
        end
      end
    end
  end
end
