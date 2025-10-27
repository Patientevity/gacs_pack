# frozen_string_literal: true

module GacsPack
  module Ports
    # Port: Graph Adapter Interface
    #
    # Implementations must provide a method to build context sections from your
    # application's knowledge graph based on subject, intent, and role.
    #
    # @example Implementing a Graph Adapter
    #   class MyGraphAdapter
    #     include GacsPack::Ports::Graph
    #
    #     def build_context(subject_id:, subject_type:, intent:, role:)
    #       {
    #         sections: [
    #           {
    #             key: "demographics",
    #             title: "Patient Demographics",
    #             body: "John Doe, Age 45...",
    #             weight: 1.0,
    #             lineage: ["patient:123", "demographics"],
    #             refs: ["patient:123"]
    #           }
    #         ]
    #       }
    #     end
    #   end
    module Graph
      # Builds context sections from the application's knowledge graph
      #
      # @param subject_id [Integer, String] The ID of the subject entity
      # @param subject_type [String] The type of the subject (e.g., "Patient", "Order")
      # @param intent [String] The purpose of this context pack (e.g., "care_gap_analysis")
      # @param role [String] The role of the requester (e.g., "provider", "patient")
      #
      # @return [Hash] A hash containing:
      #   - sections [Array<Hash>] Array of section hashes, each containing:
      #     - key [String] Unique identifier for the section
      #     - title [String] Human-readable title
      #     - body [String] The actual content
      #     - weight [Float, nil] Optional priority weight (higher = more important)
      #     - lineage [Array<String>, nil] Optional provenance trail
      #     - refs [Array<String>, nil] Optional entity references
      #
      # @raise [NotImplementedError] if not implemented by adapter
      def build_context(subject_id:, subject_type:, intent:, role:)
        raise NotImplementedError, "#{self.class} must implement #build_context"
      end
    end
  end
end
