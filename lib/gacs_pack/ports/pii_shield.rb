# frozen_string_literal: true

module GacsPack
  module Ports
    # Port: PII Shield Adapter Interface
    #
    # Implementations provide role-based and intent-aware PII redaction.
    # Ensures sensitive data is masked or removed based on access policies.
    #
    # @example Implementing a PII Shield Adapter
    #   class TenantPIIShield
    #     include GacsPack::Ports::PIIShield
    #
    #     def redact(raw_context, role:, intent:)
    #       # Apply redaction rules based on role and intent
    #       sections = raw_context[:sections].map do |section|
    #         if section[:key] == "ssn" && role != "admin"
    #           section.merge(body: "[REDACTED]")
    #         else
    #           section
    #         end
    #       end
    #       raw_context.merge(sections: sections)
    #     end
    #   end
    module PIIShield
      # Applies PII redaction to context based on role and intent
      #
      # @param raw_context [Hash] The raw context hash with :sections key
      # @param role [String] The role of the requester (e.g., "provider", "patient")
      # @param intent [String] The purpose of the context pack
      #
      # @return [Hash] The redacted context hash (same structure as input)
      #
      # @raise [NotImplementedError] if not implemented by adapter
      def redact(raw_context, role:, intent:)
        raise NotImplementedError, "#{self.class} must implement #redact"
      end
    end
  end
end
