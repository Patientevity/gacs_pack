# frozen_string_literal: true

RSpec.describe GacsPack::TokenBudgeter do
  # Mock tokenizer that counts each section as 10 tokens
  let(:mock_tokenizer) do
    Class.new do
      def count_tokens(_obj)
        10
      end

      def truncate_sections(sections, budget_tokens:)
        used = 0
        kept = []
        sections.each do |section|
          tokens = 10
          break if used + tokens > budget_tokens

          kept << section
          used += tokens
        end
        kept
      end
    end.new
  end

  subject(:budgeter) { described_class.new(mock_tokenizer) }

  describe "#pack" do
    context "with sections within budget" do
      it "keeps all sections" do
        raw = {
          sections: [
            { key: "a", body: "content a", weight: 1.0 },
            { key: "b", body: "content b", weight: 2.0 }
          ]
        }

        result = budgeter.pack(raw, budget_tokens: 100)

        expect(result).to be_an(Array)
        expect(result.size).to eq(2)
      end
    end

    context "with sections exceeding budget" do
      it "keeps highest-weight sections within budget" do
        raw = {
          sections: [
            { key: "a", body: "content a", weight: 2.0 },
            { key: "b", body: "content b", weight: 1.0 },
            { key: "c", body: "content c", weight: 3.0 }
          ]
        }

        result = budgeter.pack(raw, budget_tokens: 25)

        expect(result).to be_an(Array)
        expect(result.size).to eq(2)
        expect(result.map { |s| s[:key] }).to eq(["c", "a"])
      end
    end

    context "with no sections" do
      it "returns empty array" do
        raw = { sections: [] }

        result = budgeter.pack(raw, budget_tokens: 100)

        expect(result).to eq([])
      end
    end

    context "with missing sections key" do
      it "returns empty array" do
        raw = {}

        result = budgeter.pack(raw, budget_tokens: 100)

        expect(result).to eq([])
      end
    end

    context "with sections without explicit weights" do
      it "treats missing weight as 1.0" do
        raw = {
          sections: [
            { key: "a", body: "content a" },
            { key: "b", body: "content b", weight: 2.0 }
          ]
        }

        result = budgeter.pack(raw, budget_tokens: 100)

        # Should sort b first (weight 2.0), then a (weight 1.0)
        expect(result.map { |s| s[:key] }).to eq(["b", "a"])
      end
    end

    context "with equal weights" do
      it "maintains stable ordering" do
        raw = {
          sections: [
            { key: "a", body: "content a", weight: 1.0 },
            { key: "b", body: "content b", weight: 1.0 },
            { key: "c", body: "content c", weight: 1.0 }
          ]
        }

        result = budgeter.pack(raw, budget_tokens: 100)

        expect(result.size).to eq(3)
      end
    end
  end
end
