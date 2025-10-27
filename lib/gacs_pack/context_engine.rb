# frozen_string_literal: true

module GacsPack
  # ContextEngine orchestrates the context pack building process.
  #
  # It coordinates between all adapters (graph, tokenizer, PII shield, store, events)
  # to build, process, and persist context packs with stable identifiers.
  #
  # @example Building a context pack
  #   config = GacsPack::Config.current
  #   engine = GacsPack::ContextEngine.new(config)
  #
  #   id, snapshot = engine.build(
  #     subject_id: 123,
  #     subject_type: "Patient",
  #     intent: "care_gap_analysis",
  #     role: "provider",
  #     budget_tokens: 8000
  #   )
  class ContextEngine
    # @param cfg [GacsPack::Config] Configuration with all adapters
    def initialize(cfg)
      @cfg = cfg
    end

    # Builds a complete context pack with stable identifier
    #
    # Process flow:
    #   1. Build raw context from graph adapter
    #   2. Apply PII redaction
    #   3. Pack sections within token budget
    #   4. Create snapshot with stable hash
    #   5. Persist to store
    #   6. Emit event
    #
    # @param subject_id [Integer, String] The ID of the subject entity
    # @param subject_type [String] The type of the subject (e.g., "Patient")
    # @param intent [String] The purpose of this context pack
    # @param role [String] The role of the requester
    # @param budget_tokens [Integer] Maximum tokens allowed
    #
    # @return [Array<(String, Hash)>] Tuple of [context_pack_id, snapshot_hash]
    def build(subject_id:, subject_type:, intent:, role:, budget_tokens:)
      # 1. Build raw context from graph
      raw = @cfg.graph.build_context(
        subject_id: subject_id,
        subject_type: subject_type,
        intent: intent,
        role: role
      )

      # 2. Apply PII redaction
      redacted = @cfg.pii_shield.redact(raw, role: role, intent: intent)

      # 3. Pack sections within token budget
      budgeter = TokenBudgeter.new(@cfg.tokenizer)
      packed_sections = budgeter.pack(redacted, budget_tokens: budget_tokens)

      # 4. Create snapshot with stable hash
      snapshot = Snapshot.new(
        sections: packed_sections,
        policy_version: @cfg.policy_version || "v1",
        meta: {
          intent: intent,
          role: role,
          subject_id: subject_id,
          subject_type: subject_type
        }
      )

      # 5. Generate stable ID
      context_pack_id = snapshot.stable_hash

      # 6. Persist to store
      @cfg.store.save!(
        id: context_pack_id,
        snapshot: snapshot,
        meta: snapshot.meta
      )

      # 7. Emit event (optional)
      @cfg.events&.emit(
        :context_built,
        id: context_pack_id,
        **snapshot.meta
      )

      # 8. Return ID and snapshot hash
      [context_pack_id, snapshot.to_h]
    end
  end
end
