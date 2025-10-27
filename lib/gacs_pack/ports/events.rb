# frozen_string_literal: true

module GacsPack
  module Ports
    # Port: Events Adapter Interface
    #
    # Implementations provide observability hooks for context pack lifecycle events.
    # Useful for logging, metrics, audit trails, and debugging.
    #
    # @example Implementing an Events Adapter
    #   class RailsEventBusAdapter
    #     include GacsPack::Ports::Events
    #
    #     def emit(event_name, **payload)
    #       ActiveSupport::Notifications.instrument("gacs_pack.#{event_name}", payload)
    #     end
    #   end
    module Events
      # Emits an event with associated payload
      #
      # @param event_name [Symbol, String] The name of the event (e.g., :context_built)
      # @param payload [Hash] Event payload containing relevant data
      #
      # Common events:
      #   - :context_built - A new context pack was created
      #   - :context_truncated - Sections were truncated due to token budget
      #   - :pii_redacted - PII redaction was applied
      #
      # @return [void]
      #
      # @raise [NotImplementedError] if not implemented by adapter
      def emit(event_name, **payload)
        raise NotImplementedError, "#{self.class} must implement #emit"
      end
    end
  end
end
