# frozen_string_literal: true

module GacsPack
  module Ports
    # Port: Tokenizer Adapter Interface
    #
    # Implementations provide token counting and section truncation to fit
    # within AI model context window budgets (e.g., Claude, GPT).
    #
    # @example Implementing a Tokenizer Adapter
    #   class AnthropicTokenizer
    #     include GacsPack::Ports::Tokenizer
    #
    #     def count_tokens(obj)
    #       text = obj.is_a?(String) ? obj : JSON.generate(obj)
    #       # Use tiktoken or similar library
    #       text.scan(/\w+/).size # naive word count
    #     end
    #
    #     def truncate_sections(sections, budget_tokens:)
    #       used = 0
    #       kept = []
    #       sections.each do |section|
    #         tokens = count_tokens(section[:body])
    #         break if used + tokens > budget_tokens
    #         kept << section
    #         used += tokens
    #       end
    #       kept
    #     end
    #   end
    module Tokenizer
      # Counts tokens in a string or hash
      #
      # @param obj [String, Hash] The content to count tokens for
      #
      # @return [Integer] The token count
      #
      # @raise [NotImplementedError] if not implemented by adapter
      def count_tokens(obj)
        raise NotImplementedError, "#{self.class} must implement #count_tokens"
      end

      # Truncates sections to fit within a token budget
      #
      # Sections should already be sorted by priority (weight) in descending order.
      # Implementation should keep as many sections as possible within the budget.
      #
      # @param sections [Array<Hash>] Array of section hashes (pre-sorted by weight)
      # @param budget_tokens [Integer] Maximum tokens allowed
      #
      # @return [Array<Hash>] The truncated sections array
      #
      # @raise [NotImplementedError] if not implemented by adapter
      def truncate_sections(sections, budget_tokens:)
        raise NotImplementedError, "#{self.class} must implement #truncate_sections"
      end
    end
  end
end
