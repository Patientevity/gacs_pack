# frozen_string_literal: true

module GacsPack
  # TokenBudgeter handles packing context sections within a token budget.
  #
  # It sorts sections by weight (priority) and uses the configured tokenizer
  # to truncate sections that exceed the available token budget.
  #
  # @example Using TokenBudgeter
  #   tokenizer = MyTokenizer.new
  #   budgeter = GacsPack::TokenBudgeter.new(tokenizer)
  #
  #   raw = {
  #     sections: [
  #       { key: "a", body: "...", weight: 2.0 },
  #       { key: "b", body: "...", weight: 1.0 },
  #       { key: "c", body: "...", weight: 3.0 }
  #     ]
  #   }
  #
  #   packed = budgeter.pack(raw, budget_tokens: 1000)
  #   # => { sections: [c, a] } # highest weight sections within budget
  class TokenBudgeter
    # @param tokenizer [#count_tokens, #truncate_sections] A tokenizer adapter
    def initialize(tokenizer)
      @tokenizer = tokenizer
    end

    # Packs sections within a token budget, prioritizing by weight
    #
    # @param raw [Hash] Raw context hash with :sections key
    # @param budget_tokens [Integer] Maximum tokens allowed
    #
    # @return [Array<Hash>] Truncated sections array
    def pack(raw, budget_tokens:)
      sections = raw.fetch(:sections, [])

      # Sort by weight descending (higher weight = higher priority)
      sorted_sections = sections.sort_by { |s| -(s[:weight] || 1.0) }

      # Delegate to tokenizer for actual truncation
      @tokenizer.truncate_sections(sorted_sections, budget_tokens: budget_tokens)
    end
  end
end
