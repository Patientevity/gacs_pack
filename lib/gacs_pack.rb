# frozen_string_literal: true

require_relative "gacs_pack/version"

# Port interfaces
require_relative "gacs_pack/ports/graph"
require_relative "gacs_pack/ports/store"
require_relative "gacs_pack/ports/events"
require_relative "gacs_pack/ports/pii_shield"
require_relative "gacs_pack/ports/tokenizer"

# Core classes
require_relative "gacs_pack/config"
require_relative "gacs_pack/lineage"
require_relative "gacs_pack/snapshot"
require_relative "gacs_pack/token_budgeter"
require_relative "gacs_pack/context_engine"

# Rails integration (exposes assets like lib/gacso.png to the asset pipeline)
require_relative "gacs_pack/engine" if defined?(Rails)

module GacsPack
  class Error < StandardError; end

  class << self
    # Public: configure gacs_pack (set adapters, policy version, logger, etc.)
    #
    # Example:
    #   GacsPack.configure do |c|
    #     c.graph        = MyGraphAdapter.new
    #     c.store        = MyStoreAdapter.new
    #     c.events       = MyEventsAdapter.new
    #     c.pii_shield   = MyPIIShield.new
    #     c.tokenizer    = MyTokenizer.new
    #     c.policy_version = "caregap-v1"
    #     c.logger       = Rails.logger
    #   end
    def configure(&) = Config.configure(&)

    # Public: current config
    def config = Config.current

    # Public: build a context pack (returns [context_pack_id, snapshot])
    #
    # Params:
    #   subject_id:, subject_type:, intent:, role:, budget_tokens:
    def build(**kwargs)
      ContextEngine.new(config).build(**kwargs)
    end

    # Public: absolute path to the Gacso logo inside the gem
    #
    # Useful for CLI banners, logging, or embedding in docs.
    def logo_path
      File.expand_path("gacso.png", __dir__)
    end
  end
end
