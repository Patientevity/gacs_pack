# frozen_string_literal: true

require_relative "lib/gacs_pack/version"

Gem::Specification.new do |spec|
  spec.name                  = "gacs_pack"
  spec.version               = GacsPack::VERSION
  spec.authors               = ["Raymond Hughes"]
  spec.email                 = ["raymond.hughes@patientevity.com"]

  spec.summary               = "Graph-Aware Context System for Rails — token-budgeted, auditable context packs."
  spec.description           = "gacs_pack builds role/intent-aware, token-budgeted context packs from your knowledge graph, with stable context_pack_id, provenance, and pluggable adapters (graph, tokenizer, PII shield, store)."

  # Public repo / site (adjust org/name as needed)
  spec.homepage              = "https://github.com/Patientevity/gacs_pack"
  spec.license               = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  # Useful RubyGems metadata
  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/Patientevity/gacs_pack",
    "changelog_uri" => "https://github.com/Patientevity/gacs_pack/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://github.com/Patientevity/gacs_pack#readme",
    "bug_tracker_uri" => "https://github.com/Patientevity/gacs_pack/issues",
    "rubygems_mfa_required" => "true"
    # "allowed_push_host"    => "https://your.private.gem.server" # uncomment if pushing to a private host
  }

  # Package all files tracked by git, minus a few exclusions
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(["git", "ls-files", "-z"], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(
          "bin/", "test/", "spec/", "features/", ".git", "appveyor"
        )
    end
  end

  # Executables (if you add any under exe/)
  spec.bindir       = "exe"
  spec.executables  = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime deps (add as you wire things up)
  # ActiveSupport 8.x requires Ruby >= 3.2, constrain to 7.x for Ruby 3.1 compatibility
  spec.add_dependency "activesupport", ">= 7.0", "< 8.0"
  spec.add_dependency "json", ">= 2.6"

  # Dev/test suggestions (optional — add to your Gemfile instead if you prefer)
  # spec.add_development_dependency "rspec", "~> 3.12"
  # spec.add_development_dependency "rubocop", "~> 1.66"
  # spec.add_development_dependency "rake", ">= 13.0"
end
