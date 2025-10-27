# Token Budgeting

## Overview

Token budgeting ensures context packs fit within AI model context windows (e.g., 8K, 100K, 200K tokens) while prioritizing the most important sections.

## How It Works

### 1. Section Weights

Each section can specify a `weight` (Float) indicating priority:

```ruby
{
  key: "current_medications",
  body: "...",
  weight: 3.0  # High priority
}
```

- **Higher weight = higher priority**
- **Default weight = 1.0** if omitted
- Sections are sorted descending by weight before truncation

### 2. TokenBudgeter

The `TokenBudgeter` class:
1. Sorts sections by weight (descending)
2. Passes sorted sections to the `Tokenizer` adapter
3. Tokenizer truncates to fit budget

```ruby
budgeter = GacsPack::TokenBudgeter.new(tokenizer)
packed = budgeter.pack(raw_context, budget_tokens: 8000)
```

### 3. Tokenizer Adapter

Your `Tokenizer` implementation:
- Counts tokens for each section
- Keeps sections until budget is exceeded
- Optionally truncates the last section to fit

Example:

```ruby
def truncate_sections(sections, budget_tokens:)
  used = 0
  kept = []

  sections.each do |section|
    tokens = count_tokens(section[:body])

    if used + tokens > budget_tokens
      # Option A: Drop this section entirely
      break

      # Option B: Truncate this section to fit
      # remaining = budget_tokens - used
      # kept << truncate_section(section, remaining)
      # break
    end

    kept << section
    used += tokens
  end

  kept
end
```

## Budgeting Strategies

### Strategy 1: Fixed Weights

Assign fixed priorities to section types:

```ruby
SECTION_WEIGHTS = {
  "demographics" => 1.0,
  "current_medications" => 3.0,
  "allergies" => 2.5,
  "vitals" => 2.0,
  "historical_conditions" => 1.5
}

sections.map do |section|
  section.merge(weight: SECTION_WEIGHTS[section[:key]] || 1.0)
end
```

### Strategy 2: Intent-Aware Weights

Adjust weights based on intent:

```ruby
def assign_weights(sections, intent:)
  sections.map do |section|
    weight = case intent
    when "care_gap_analysis"
      care_gap_weight(section)
    when "medication_review"
      medication_weight(section)
    else
      1.0
    end

    section.merge(weight: weight)
  end
end

def care_gap_weight(section)
  case section[:key]
  when "conditions" then 3.0
  when "labs" then 2.5
  else 1.0
  end
end
```

### Strategy 3: Recency-Based Weights

Prioritize recent data:

```ruby
def recency_weight(timestamp)
  days_ago = (Time.current - timestamp) / 1.day

  if days_ago < 7
    3.0
  elsif days_ago < 30
    2.0
  elsif days_ago < 90
    1.5
  else
    1.0
  end
end
```

## Example: Budget-Aware Context Building

```ruby
def build_context(subject_id:, subject_type:, intent:, role:)
  patient = Patient.find(subject_id)

  sections = [
    {
      key: "demographics",
      title: "Demographics",
      body: render_demographics(patient),
      weight: 1.0
    },
    {
      key: "medications",
      title: "Current Medications",
      body: render_medications(patient),
      weight: intent == "medication_review" ? 3.0 : 2.0
    },
    {
      key: "labs",
      title: "Recent Labs",
      body: render_labs(patient),
      weight: intent == "care_gap" ? 2.5 : 1.5
    }
  ]

  { sections: sections }
end
```

## Monitoring Token Usage

Subscribe to events to track truncation:

```ruby
ActiveSupport::Notifications.subscribe("gacs_pack.context_built") do |_name, _start, _finish, _id, payload|
  Rails.logger.info("Context built: #{payload[:id]}")

  # Track metrics
  Metrics.increment("gacs_pack.context_built", tags: {
    intent: payload[:intent],
    role: payload[:role]
  })
end
```

## Best Practices

1. **Start with sensible defaults**: Most sections weight 1.0
2. **Use 3-5 priority tiers**: Avoid too many distinct weights
3. **Test with real data**: Measure actual token counts for your content
4. **Monitor truncation**: Track how often sections are dropped
5. **Adjust iteratively**: Refine weights based on AI output quality
