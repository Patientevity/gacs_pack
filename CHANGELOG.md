## [Unreleased]

## [0.1.0] - 2025-10-26

### Added

- **Core Architecture**: Ports & Adapters (Hexagonal) architecture for pluggable components
- **Port Interfaces**: Five adapter interfaces for extending functionality
  - `Ports::Graph` - Build context sections from knowledge graphs
  - `Ports::Store` - Persist context packs
  - `Ports::Events` - Observability and event hooks
  - `Ports::PIIShield` - Role/intent-aware PII redaction
  - `Ports::Tokenizer` - Token counting and budget enforcement

- **Core Classes**:
  - `ContextEngine` - Orchestrates context pack building
  - `TokenBudgeter` - Weight-based section prioritization
  - `Snapshot` - Immutable context packs with stable SHA256 IDs
  - `Lineage` - Provenance tracking across sections

- **Rails Integration**:
  - Rails Engine for asset pipeline integration
  - Generator: `rails g gacs_pack:install` creates migration for `context_packs` table
  - Supports Rails 7.0+

- **Type Safety**:
  - Complete RBS type signatures for all public APIs
  - Steep configuration for static type checking

- **Testing**:
  - Comprehensive RSpec test suite (42 examples, 100% passing)
  - Test doubles for all port adapters
  - CI via GitHub Actions (Ruby 3.1, 3.2, 3.3)

- **Documentation**:
  - Architecture guide
  - Adapter implementation guide with examples
  - Intent templates guide
  - Token budgeting strategies
  - YARD API documentation

- **Code Quality**:
  - RuboCop linting with sensible defaults
  - Frozen string literals throughout
  - Ruby 3.1+ required (leveraging modern syntax)

### Features

- **Stable Context IDs**: Deterministic SHA256 hashing ensures identical content produces identical IDs
- **Token Budgeting**: Weight-based prioritization keeps high-value sections within AI model limits
- **Role/Intent Awareness**: Customize sections, weights, and PII based on use case
- **Provenance Tracking**: Full lineage trail from source data to context pack
- **Multi-tenancy Support**: Built-in tenant_id column for SaaS applications
