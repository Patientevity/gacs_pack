# Architecture

## Overview

`gacs_pack` uses a **Ports & Adapters** (Hexagonal) architecture to keep the core domain logic independent of specific implementations.

## Core Components

### 1. ContextEngine

The orchestrator that coordinates all operations:

```
┌──────────────────┐
│  ContextEngine   │
└────────┬─────────┘
         │
    ┌────┴────┐
    │ Config  │  ← Dependency injection
    └────┬────┘
         │
    ┌────┴─────────────────────────┐
    │  Port Adapters (pluggable)   │
    ├──────────────────────────────┤
    │  - Graph                     │
    │  - PIIShield                 │
    │  - Tokenizer                 │
    │  - Store                     │
    │  - Events                    │
    └──────────────────────────────┘
```

### 2. Ports (Interfaces)

Five adapter interfaces define the contract between core logic and external systems:

- **Graph**: Builds context sections from your knowledge graph
- **PIIShield**: Applies role/intent-aware redaction
- **Tokenizer**: Counts tokens and truncates to budget
- **Store**: Persists context packs
- **Events**: Observability hooks

### 3. Core Domain Classes

- **TokenBudgeter**: Prioritizes and packs sections by weight
- **Snapshot**: Immutable context pack with stable hashing
- **Lineage**: Aggregates provenance trails

## Data Flow

```
1. Graph → raw context sections
2. PIIShield → redacted sections
3. TokenBudgeter → prioritized sections (by weight)
4. Tokenizer → truncated sections (within budget)
5. Snapshot → immutable pack with SHA256 ID
6. Store → persisted
7. Events → emitted for observability
```

## Design Principles

1. **Port-Driven Design**: Core logic never depends on specific implementations
2. **Immutability**: Snapshots are immutable; stable hashing ensures deterministic IDs
3. **Observability**: Events provide hooks for logging, metrics, and audit
4. **Testability**: All dependencies are injectable; easy to mock

## Extension Points

To customize `gacs_pack` for your application:

1. Implement the 5 port interfaces
2. Configure adapters in your Rails initializer
3. Optionally customize TokenBudgeter weights or Snapshot meta

See [adapters.md](./adapters.md) for implementation examples.
