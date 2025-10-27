# Quick Start Guide

Get up and running with `gacs_pack` in 5 minutes!

## Installation

### 1. Add to Your Gemfile

```ruby
gem "gacs_pack"
```

### 2. Install Dependencies

```bash
bundle install
```

### 3. Run the Generator

The generator creates a migration for the `context_packs` table:

```bash
bin/rails generate gacs_pack:install
bin/rails db:migrate
```

This creates a `context_packs` table with:
- `id` (string, primary key) - The stable context_pack_id (SHA256 hash)
- `tenant_id` (bigint) - For multi-tenancy support
- `payload` (jsonb) - The full snapshot data
- `meta` (jsonb) - Metadata (intent, role, subject_id, etc.)
- `created_at`, `updated_at` - Timestamps

## Configuration

### 4. Implement Your Adapters

You need to implement 5 adapter interfaces. Here's a minimal example:

#### Graph Adapter

```ruby
# app/lib/my_graph_adapter.rb
class MyGraphAdapter
  include GacsPack::Ports::Graph

  def build_context(subject_id:, subject_type:, intent:, role:)
    # Build sections from your data
    patient = Patient.find(subject_id)

    {
      sections: [
        {
          key: "demographics",
          title: "Patient Demographics",
          body: "Name: #{patient.name}, Age: #{patient.age}",
          weight: 1.0
        },
        {
          key: "conditions",
          title: "Active Conditions",
          body: patient.conditions.map(&:name).join(", "),
          weight: 2.0  # Higher priority
        }
      ]
    }
  end
end
```

#### Tokenizer Adapter

```ruby
# app/lib/my_tokenizer.rb
class MyTokenizer
  include GacsPack::Ports::Tokenizer

  def count_tokens(obj)
    text = obj.is_a?(String) ? obj : JSON.generate(obj)
    # Simple word count (replace with tiktoken or similar)
    text.split.size
  end

  def truncate_sections(sections, budget_tokens:)
    used = 0
    kept = []

    sections.each do |section|
      tokens = count_tokens(section[:body])
      break if used + tokens > budget_tokens

      kept << section
      used += tokens
    end

    kept
  end
end
```

#### PIIShield Adapter

```ruby
# app/lib/my_pii_shield.rb
class MyPIIShield
  include GacsPack::Ports::PIIShield

  def redact(raw_context, role:, intent:)
    # Simple pass-through for now
    # Add your PII redaction logic here
    raw_context
  end
end
```

#### Store Adapter

```ruby
# app/lib/my_store.rb
class MyStore
  include GacsPack::Ports::Store

  def save!(id:, snapshot:, meta:)
    ContextPack.upsert({
      id: id,
      tenant_id: Current.tenant_id, # If using multi-tenancy
      payload: snapshot.to_h,
      meta: meta,
      created_at: Time.current,
      updated_at: Time.current
    }, unique_by: :id)
  end
end
```

#### Events Adapter

```ruby
# app/lib/my_events.rb
class MyEvents
  include GacsPack::Ports::Events

  def emit(event_name, **payload)
    Rails.logger.info("gacs_pack.#{event_name}: #{payload.inspect}")
  end
end
```

### 5. Configure gacs_pack

Create an initializer:

```ruby
# config/initializers/gacs_pack.rb
GacsPack.configure do |config|
  config.graph          = MyGraphAdapter.new
  config.tokenizer      = MyTokenizer.new
  config.pii_shield     = MyPIIShield.new
  config.store          = MyStore.new
  config.events         = MyEvents.new
  config.policy_version = "v1"
  config.logger         = Rails.logger
end
```

## Usage

### Build Your First Context Pack

```ruby
# In a controller or service
context_pack_id, snapshot = GacsPack.build(
  subject_id: patient.id,
  subject_type: "Patient",
  intent: "care_gap_analysis",
  role: "provider",
  budget_tokens: 8000
)

# Use the context_pack_id for provenance
ai_response = call_ai_api(snapshot[:sections])

# Store the ID with your AI output
AiOutput.create!(
  context_pack_id: context_pack_id,
  response: ai_response,
  intent: "care_gap_analysis"
)
```

### Example: Care Gap Analysis

```ruby
class CareGapService
  def analyze(patient_id)
    # Build context pack
    context_id, snapshot = GacsPack.build(
      subject_id: patient_id,
      subject_type: "Patient",
      intent: "care_gap_analysis",
      role: "provider",
      budget_tokens: 8000
    )

    # Format for AI
    prompt = build_prompt(snapshot[:sections])

    # Call your AI service
    response = claude_api.messages.create(
      model: "claude-3-5-sonnet-20241022",
      max_tokens: 2000,
      messages: [{
        role: "user",
        content: prompt
      }]
    )

    # Return with provenance
    {
      context_pack_id: context_id,
      gaps: parse_gaps(response),
      ai_response: response
    }
  end

  private

  def build_prompt(sections)
    context = sections.map { |s| "#{s[:title]}:\n#{s[:body]}" }.join("\n\n")

    <<~PROMPT
      You are a healthcare AI assistant. Analyze the following patient data
      and identify any care gaps (missing preventive screenings, medications, etc.).

      #{context}

      Please list any care gaps you identify.
    PROMPT
  end
end
```

## Next Steps

Now that you have `gacs_pack` running, explore these advanced topics:

1. **[Adapters & Ports](./adapters.md)** - Implement production-ready adapters
2. **[Intent Templates](./intents.md)** - Design intent-specific context building
3. **[Token Budgeting](./token_budgeting.md)** - Optimize section prioritization
4. **[Architecture](./architecture.md)** - Understand the design patterns

## Common Issues

### "NoMethodError: undefined method 'build_context'"

Make sure your adapter includes the port module:

```ruby
class MyGraphAdapter
  include GacsPack::Ports::Graph  # ← Don't forget this!

  def build_context(subject_id:, subject_type:, intent:, role:)
    # ...
  end
end
```

### "PG::UndefinedTable: ERROR: relation 'context_packs' does not exist"

Run the migration:

```bash
bin/rails db:migrate
```

### Context pack is too large

Adjust your token budget or increase section weights for important data:

```ruby
GacsPack.build(
  subject_id: patient.id,
  subject_type: "Patient",
  intent: "care_gap_analysis",
  role: "provider",
  budget_tokens: 16000  # ← Increase budget
)
```

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/Patientevity/gacs_pack/issues)
- **Contributing**: See [CONTRIBUTING.md](../CONTRIBUTING.md)
- **Discussions**: [GitHub Discussions](https://github.com/Patientevity/gacs_pack/discussions)

Ready to build production-ready adapters? Check out the [Adapters Guide](./adapters.md)!
