# frozen_string_literal: true

module GacsPack
  module Ports
    # Port: Store Adapter Interface
    #
    # Implementations must provide persistence for context pack snapshots.
    # Typically backed by a database (PostgreSQL JSONB, MongoDB, etc.)
    #
    # @example Implementing a Store Adapter with ActiveRecord
    #   class ActiveRecordSnapshotStore
    #     include GacsPack::Ports::Store
    #
    #     def save!(id:, snapshot:, meta:)
    #       ContextPack.upsert({
    #         id: id,
    #         tenant_id: Current.tenant_id,
    #         payload: snapshot.to_h,
    #         meta: meta,
    #         created_at: Time.current,
    #         updated_at: Time.current
    #       }, unique_by: :id)
    #     end
    #   end
    module Store
      # Persists a context pack snapshot
      #
      # @param id [String] The stable context_pack_id (SHA256 hash)
      # @param snapshot [GacsPack::Snapshot, Hash] The snapshot object or hash
      # @param meta [Hash] Additional metadata (intent, role, subject_id, etc.)
      #
      # @return [void]
      #
      # @raise [NotImplementedError] if not implemented by adapter
      def save!(id:, snapshot:, meta:)
        raise NotImplementedError, "#{self.class} must implement #save!"
      end
    end
  end
end
