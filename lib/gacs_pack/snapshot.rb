# frozen_string_literal: true

require "json"
require "digest"

module GacsPack
  # Snapshot represents an immutable context pack with stable hashing.
  #
  # Each snapshot contains sections, policy version, metadata, and computed lineage.
  # The stable_hash provides a deterministic SHA256 identifier (context_pack_id)
  # based on canonical JSON representation.
  #
  # @example Creating a snapshot
  #   sections = [
  #     { key: "demographics", title: "Demographics", body: "...", weight: 1.0 }
  #   ]
  #
  #   snapshot = GacsPack::Snapshot.new(
  #     sections: sections,
  #     policy_version: "v1",
  #     meta: { intent: "care_gap", role: "provider" }
  #   )
  #
  #   snapshot.stable_hash # => "a1b2c3d4..."
  class Snapshot
    attr_reader :sections, :policy_version, :meta

    # @param sections [Array<Hash>] Array of context section hashes
    # @param policy_version [String] The policy version identifier
    # @param meta [Hash] Additional metadata (intent, role, etc.)
    def initialize(sections:, policy_version:, meta: {})
      @sections = sections
      @policy_version = policy_version
      @meta = meta
    end

    # Converts snapshot to a hash representation
    #
    # @return [Hash] Hash containing sections, policy_version, meta, and lineage
    def to_h
      {
        sections: sections,
        policy_version: policy_version,
        meta: meta,
        lineage: Lineage.from(sections)
      }
    end

    # Generates canonical JSON representation
    #
    # Uses compact JSON (no whitespace) with consistent ordering
    # to ensure identical snapshots produce identical JSON.
    #
    # @return [String] Canonical JSON string
    def canonical_json
      # Use compact JSON generation (no spaces) for deterministic output
      JSON.generate(to_h, space: nil, object_nl: "", array_nl: "")
    end

    # Computes stable SHA256 hash of canonical JSON
    #
    # This hash serves as the context_pack_id and ensures
    # identical content produces identical IDs.
    #
    # @return [String] 64-character hexadecimal SHA256 hash
    def stable_hash
      Digest::SHA256.hexdigest(canonical_json)
    end
  end
end
