# Adapters & Ports

## Overview

`gacs_pack` requires five adapter implementations to connect your Rails app's domain logic to the gem's context-building pipeline.

## Required Adapters

### 1. Graph Adapter

Builds context sections from your knowledge graph.

```ruby
class PatientevityGraphAdapter
  include GacsPack::Ports::Graph

  def build_context(subject_id:, subject_type:, intent:, role:)
    patient = Patient.find(subject_id)

    {
      sections: [
        {
          key: "demographics",
          title: "Demographics",
          body: render_demographics(patient),
          weight: 1.0,
          lineage: ["patient:#{patient.id}", "demographics"],
          refs: ["patient:#{patient.id}"]
        },
        {
          key: "conditions",
          title: "Conditions",
          body: render_conditions(patient),
          weight: 1.5, # Higher priority
          lineage: ["patient:#{patient.id}", "conditions"],
          refs: patient.conditions.pluck(:id).map { |id| "condition:#{id}" }
        }
      ]
    }
  end

  private

  def render_demographics(patient)
    # Build text representation
  end

  def render_conditions(patient)
    # Build text representation
  end
end
```

### 2. PIIShield Adapter

Applies role-based and intent-aware redaction.

```ruby
class TenantPIIShield
  include GacsPack::Ports::PIIShield

  def redact(raw_context, role:, intent:)
    sections = raw_context[:sections].map do |section|
      case role
      when "patient"
        # Patients can see everything
        section
      when "provider"
        # Providers can't see SSN unless intent is billing
        if section[:key] == "ssn" && intent != "billing"
          section.merge(body: "[REDACTED]")
        else
          section
        end
      else
        section.merge(body: "[UNAUTHORIZED]")
      end
    end

    raw_context.merge(sections: sections)
  end
end
```

### 3. Tokenizer Adapter

Counts tokens and truncates sections to fit budget.

```ruby
class AnthropicTokenizer
  include GacsPack::Ports::Tokenizer

  def count_tokens(obj)
    text = obj.is_a?(String) ? obj : JSON.generate(obj)
    # Use tiktoken, tokenizers gem, or API call
    Tiktoken.count(text, model: "claude-3-5-sonnet")
  end

  def truncate_sections(sections, budget_tokens:)
    used = 0
    kept = []

    sections.each do |section|
      tokens = count_tokens(section[:body])

      if used + tokens > budget_tokens
        # Try truncating this section
        remaining = budget_tokens - used
        if remaining > 100 # minimum viable
          truncated_body = truncate_text(section[:body], remaining)
          kept << section.merge(body: truncated_body, truncated: true)
        end
        break
      end

      kept << section
      used += tokens
    end

    kept
  end

  private

  def truncate_text(text, max_tokens)
    # Truncate text to fit max_tokens
  end
end
```

### 4. Store Adapter

Persists context packs (typically PostgreSQL with JSONB).

```ruby
class ActiveRecordSnapshotStore
  include GacsPack::Ports::Store

  def save!(id:, snapshot:, meta:)
    ContextPack.upsert({
      id: id,
      tenant_id: Current.tenant_id,
      payload: snapshot.to_h,
      meta: meta,
      created_at: Time.current,
      updated_at: Time.current
    }, unique_by: :id)
  end
end
```

### 5. Events Adapter

Emits observability events.

```ruby
class RailsEventBusAdapter
  include GacsPack::Ports::Events

  def emit(event_name, **payload)
    ActiveSupport::Notifications.instrument("gacs_pack.#{event_name}", payload)
    Rails.logger.info("gacs_pack.#{event_name}: #{payload.inspect}")
  end
end
```

## Configuration

Wire up your adapters in `config/initializers/gacs_pack.rb`:

```ruby
GacsPack.configure do |c|
  c.graph          = PatientevityGraphAdapter.new
  c.pii_shield     = TenantPIIShield.new
  c.tokenizer      = AnthropicTokenizer.new
  c.store          = ActiveRecordSnapshotStore.new
  c.events         = RailsEventBusAdapter.new
  c.policy_version = "caregap-v1"
  c.logger         = Rails.logger
end
```

## Testing Your Adapters

Write unit tests for each adapter in isolation:

```ruby
RSpec.describe PatientevityGraphAdapter do
  it "builds sections for a patient" do
    patient = create(:patient)
    adapter = described_class.new

    result = adapter.build_context(
      subject_id: patient.id,
      subject_type: "Patient",
      intent: "care_gap",
      role: "provider"
    )

    expect(result[:sections]).to be_an(Array)
    expect(result[:sections].first).to include(:key, :title, :body)
  end
end
```
