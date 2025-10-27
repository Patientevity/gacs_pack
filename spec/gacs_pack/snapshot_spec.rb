# frozen_string_literal: true

RSpec.describe GacsPack::Snapshot do
  let(:sections) do
    [
      { key: "demographics", title: "Demographics", body: "Patient: John Doe", weight: 1.0 }
    ]
  end

  let(:policy_version) { "v1" }
  let(:meta) { { intent: "care_gap", role: "provider" } }

  subject(:snapshot) do
    described_class.new(
      sections: sections,
      policy_version: policy_version,
      meta: meta
    )
  end

  describe "#initialize" do
    it "sets sections" do
      expect(snapshot.sections).to eq(sections)
    end

    it "sets policy_version" do
      expect(snapshot.policy_version).to eq(policy_version)
    end

    it "sets meta" do
      expect(snapshot.meta).to eq(meta)
    end

    it "accepts empty meta" do
      snapshot = described_class.new(
        sections: sections,
        policy_version: policy_version
      )

      expect(snapshot.meta).to eq({})
    end
  end

  describe "#to_h" do
    it "returns hash with all components" do
      result = snapshot.to_h

      expect(result).to include(
        sections: sections,
        policy_version: policy_version,
        meta: meta,
        lineage: []
      )
    end

    it "includes computed lineage from sections" do
      sections_with_lineage = [
        { key: "demo", lineage: ["patient:123", "demographics"] }
      ]

      snapshot = described_class.new(
        sections: sections_with_lineage,
        policy_version: policy_version,
        meta: meta
      )

      result = snapshot.to_h

      expect(result[:lineage]).to match_array(["patient:123", "demographics"])
    end
  end

  describe "#canonical_json" do
    it "returns JSON string" do
      result = snapshot.canonical_json

      expect(result).to be_a(String)
      expect { JSON.parse(result) }.not_to raise_error
    end

    it "uses compact format (no whitespace)" do
      result = snapshot.canonical_json

      expect(result).not_to include("\n")
      expect(result).not_to match(/\s{2,}/)
    end

    it "produces identical JSON for identical snapshots" do
      snapshot1 = described_class.new(
        sections: sections,
        policy_version: policy_version,
        meta: meta
      )

      snapshot2 = described_class.new(
        sections: sections,
        policy_version: policy_version,
        meta: meta
      )

      expect(snapshot1.canonical_json).to eq(snapshot2.canonical_json)
    end
  end

  describe "#stable_hash" do
    it "returns SHA256 hex digest" do
      result = snapshot.stable_hash

      expect(result).to be_a(String)
      expect(result).to match(/\A[a-f0-9]{64}\z/)
    end

    it "produces identical hash for identical content" do
      snapshot1 = described_class.new(
        sections: sections,
        policy_version: policy_version,
        meta: meta
      )

      snapshot2 = described_class.new(
        sections: sections,
        policy_version: policy_version,
        meta: meta
      )

      expect(snapshot1.stable_hash).to eq(snapshot2.stable_hash)
    end

    it "produces different hash for different content" do
      snapshot1 = described_class.new(
        sections: sections,
        policy_version: "v1",
        meta: meta
      )

      snapshot2 = described_class.new(
        sections: sections,
        policy_version: "v2",
        meta: meta
      )

      expect(snapshot1.stable_hash).not_to eq(snapshot2.stable_hash)
    end

    it "is deterministic across multiple calls" do
      hash1 = snapshot.stable_hash
      hash2 = snapshot.stable_hash
      hash3 = snapshot.stable_hash

      expect(hash1).to eq(hash2)
      expect(hash2).to eq(hash3)
    end
  end
end
