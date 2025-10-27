# frozen_string_literal: true

RSpec.describe GacsPack::Lineage do
  describe ".from" do
    context "with sections containing lineage" do
      it "aggregates unique lineage entries" do
        sections = [
          { key: "demographics", lineage: ["patient:123", "demographics"] },
          { key: "conditions", lineage: ["patient:123", "conditions", "icd10:E11"] }
        ]

        result = described_class.from(sections)

        expect(result).to match_array([
                                        "patient:123",
                                        "demographics",
                                        "conditions",
                                        "icd10:E11"
                                      ])
      end

      it "removes duplicate lineage entries" do
        sections = [
          { key: "a", lineage: ["patient:123", "demographics"] },
          { key: "b", lineage: ["patient:123", "demographics"] }
        ]

        result = described_class.from(sections)

        expect(result).to match_array(["patient:123", "demographics"])
      end
    end

    context "with sections without lineage" do
      it "returns empty array" do
        sections = [
          { key: "a", body: "content" },
          { key: "b", body: "content" }
        ]

        result = described_class.from(sections)

        expect(result).to eq([])
      end
    end

    context "with nil lineage values" do
      it "handles nil gracefully" do
        sections = [
          { key: "a", lineage: nil },
          { key: "b", lineage: ["patient:123"] }
        ]

        result = described_class.from(sections)

        expect(result).to eq(["patient:123"])
      end
    end

    context "with empty sections array" do
      it "returns empty array" do
        result = described_class.from([])

        expect(result).to eq([])
      end
    end

    context "with nil sections" do
      it "returns empty array" do
        result = described_class.from(nil)

        expect(result).to eq([])
      end
    end

    context "with mixed lineage formats" do
      it "flattens and aggregates correctly" do
        sections = [
          { key: "a", lineage: ["x", "y"] },
          { key: "b", lineage: ["z"] },
          { key: "c", lineage: ["x", "z"] }
        ]

        result = described_class.from(sections)

        expect(result).to match_array(["x", "y", "z"])
      end
    end
  end
end
