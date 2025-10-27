# frozen_string_literal: true

RSpec.describe GacsPack::ContextEngine do
  # Mock adapters
  let(:mock_graph) do
    double("graph", build_context: {
             sections: [
               { key: "demo", title: "Demographics", body: "Patient data...", weight: 1.0 }
             ]
           })
  end

  let(:mock_pii_shield) do
    double("pii_shield").tap do |shield|
      allow(shield).to receive(:redact) do |raw, **_opts|
        raw
      end
    end
  end

  let(:mock_tokenizer) do
    double("tokenizer", truncate_sections: [
             { key: "demo", title: "Demographics", body: "Patient data...", weight: 1.0 }
           ])
  end

  let(:mock_store) do
    double("store", save!: true)
  end

  let(:mock_events) do
    double("events", emit: true)
  end

  let(:config) do
    instance_double(
      GacsPack::Config,
      graph: mock_graph,
      pii_shield: mock_pii_shield,
      tokenizer: mock_tokenizer,
      store: mock_store,
      events: mock_events,
      policy_version: "v1",
      logger: nil
    )
  end

  subject(:engine) { described_class.new(config) }

  describe "#build" do
    let(:build_params) do
      {
        subject_id: 123,
        subject_type: "Patient",
        intent: "care_gap_analysis",
        role: "provider",
        budget_tokens: 8000
      }
    end

    it "returns context_pack_id and snapshot hash" do
      id, snapshot = engine.build(**build_params)

      expect(id).to be_a(String)
      expect(id).to match(/\A[a-f0-9]{64}\z/)
      expect(snapshot).to be_a(Hash)
    end

    it "calls graph adapter with correct parameters" do
      engine.build(**build_params)

      expect(mock_graph).to have_received(:build_context).with(
        subject_id: 123,
        subject_type: "Patient",
        intent: "care_gap_analysis",
        role: "provider"
      )
    end

    it "calls PII shield with raw context" do
      engine.build(**build_params)

      expect(mock_pii_shield).to have_received(:redact).with(
        hash_including(sections: array_including(hash_including(key: "demo"))),
        role: "provider",
        intent: "care_gap_analysis"
      )
    end

    it "calls tokenizer with sections and budget" do
      engine.build(**build_params)

      expect(mock_tokenizer).to have_received(:truncate_sections).with(
        array_including(hash_including(key: "demo")),
        budget_tokens: 8000
      )
    end

    it "persists to store with stable ID" do
      id, _snapshot = engine.build(**build_params)

      expect(mock_store).to have_received(:save!).with(
        hash_including(
          id: id,
          snapshot: instance_of(GacsPack::Snapshot),
          meta: hash_including(
            intent: "care_gap_analysis",
            role: "provider",
            subject_id: 123,
            subject_type: "Patient"
          )
        )
      )
    end

    it "emits context_built event" do
      id, _snapshot = engine.build(**build_params)

      expect(mock_events).to have_received(:emit).with(
        :context_built,
        hash_including(
          id: id,
          intent: "care_gap_analysis",
          role: "provider",
          subject_id: 123,
          subject_type: "Patient"
        )
      )
    end

    it "includes policy_version in snapshot" do
      _id, snapshot = engine.build(**build_params)

      expect(snapshot[:policy_version]).to eq("v1")
    end

    it "includes meta in snapshot" do
      _id, snapshot = engine.build(**build_params)

      expect(snapshot[:meta]).to include(
        intent: "care_gap_analysis",
        role: "provider",
        subject_id: 123,
        subject_type: "Patient"
      )
    end

    it "includes lineage in snapshot" do
      _id, snapshot = engine.build(**build_params)

      expect(snapshot).to have_key(:lineage)
      expect(snapshot[:lineage]).to be_an(Array)
    end

    context "when events adapter is nil" do
      let(:config_without_events) do
        instance_double(
          GacsPack::Config,
          graph: mock_graph,
          pii_shield: mock_pii_shield,
          tokenizer: mock_tokenizer,
          store: mock_store,
          events: nil,
          policy_version: "v1",
          logger: nil
        )
      end

      it "does not emit events" do
        engine = described_class.new(config_without_events)

        expect { engine.build(**build_params) }.not_to raise_error
      end
    end

    context "with sections containing lineage" do
      let(:mock_graph_with_lineage) do
        double("graph", build_context: {
                 sections: [
                   {
                     key: "demo",
                     title: "Demographics",
                     body: "...",
                     weight: 1.0,
                     lineage: ["patient:123", "demographics"]
                   }
                 ]
               })
      end

      let(:mock_tokenizer_with_lineage) do
        double("tokenizer", truncate_sections: [
                 {
                   key: "demo",
                   title: "Demographics",
                   body: "...",
                   weight: 1.0,
                   lineage: ["patient:123", "demographics"]
                 }
               ])
      end

      let(:config_with_lineage) do
        instance_double(
          GacsPack::Config,
          graph: mock_graph_with_lineage,
          pii_shield: mock_pii_shield,
          tokenizer: mock_tokenizer_with_lineage,
          store: mock_store,
          events: mock_events,
          policy_version: "v1",
          logger: nil
        )
      end

      it "aggregates lineage in snapshot" do
        engine = described_class.new(config_with_lineage)
        _id, snapshot = engine.build(**build_params)

        expect(snapshot[:lineage]).to include("patient:123", "demographics")
      end
    end

    context "with default policy version" do
      let(:config_no_version) do
        instance_double(
          GacsPack::Config,
          graph: mock_graph,
          pii_shield: mock_pii_shield,
          tokenizer: mock_tokenizer,
          store: mock_store,
          events: mock_events,
          policy_version: nil,
          logger: nil
        )
      end

      it "defaults to v1" do
        engine = described_class.new(config_no_version)
        _id, snapshot = engine.build(**build_params)

        expect(snapshot[:policy_version]).to eq("v1")
      end
    end

    context "with identical inputs" do
      it "produces identical context_pack_id" do
        id1, _snapshot1 = engine.build(**build_params)
        id2, _snapshot2 = engine.build(**build_params)

        expect(id1).to eq(id2)
      end
    end
  end
end
