# frozen_string_literal: true

module GacsPack
  class Config
    attr_accessor :graph, :store, :events, :pii_shield, :tokenizer, :logger, :policy_version

    def self.configure
      @current ||= new
      yield @current
      @current
    end

    def self.current
      @current ||= new
    end
  end
end
