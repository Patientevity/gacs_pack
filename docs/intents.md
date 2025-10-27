# Intent Templates

## Overview

**Intents** define the purpose of a context pack and guide which sections to include, how to prioritize them, and what PII redaction rules to apply.

## What is an Intent?

An intent is a string identifier that describes why you're building a context pack:

```ruby
GacsPack.build(
  subject_id: patient.id,
  subject_type: "Patient",
  intent: "care_gap_analysis",  # ← The intent
  role: "provider",
  budget_tokens: 8000
)
```

Intents allow you to:
- Include/exclude specific sections
- Adjust section weights
- Apply intent-specific PII redaction
- Customize output format

## Example Intents

### 1. Care Gap Analysis

**Purpose**: Identify missing preventive care measures

**Sections**:
- Demographics (low priority)
- Current conditions (high priority)
- Medications (medium priority)
- Labs (high priority)
- Preventive screenings (high priority)

**Implementation**:

```ruby
def build_context(subject_id:, subject_type:, intent:, role:)
  patient = Patient.find(subject_id)

  sections = if intent == "care_gap_analysis"
    care_gap_sections(patient)
  elsif intent == "medication_review"
    medication_sections(patient)
  else
    default_sections(patient)
  end

  { sections: sections }
end

private

def care_gap_sections(patient)
  [
    {
      key: "demographics",
      title: "Demographics",
      body: render_demographics(patient),
      weight: 1.0
    },
    {
      key: "conditions",
      title: "Diagnoses",
      body: render_conditions(patient),
      weight: 3.0  # High priority for care gaps
    },
    {
      key: "labs",
      title: "Recent Labs",
      body: render_recent_labs(patient, days: 90),
      weight: 2.5
    },
    {
      key: "screenings",
      title: "Preventive Screenings",
      body: render_screenings(patient),
      weight: 3.0  # Essential for care gaps
    }
  ]
end
```

### 2. Medication Review

**Purpose**: Review drug interactions, duplicates, and contraindications

**Sections**:
- Current medications (highest priority)
- Allergies (high priority)
- Conditions (medium priority)
- Labs (low priority for interactions)

```ruby
def medication_sections(patient)
  [
    {
      key: "medications",
      title: "Current Medications",
      body: render_medications(patient),
      weight: 5.0  # Highest priority
    },
    {
      key: "allergies",
      title: "Allergies",
      body: render_allergies(patient),
      weight: 4.0
    },
    {
      key: "conditions",
      title: "Diagnoses",
      body: render_conditions(patient),
      weight: 2.0
    },
    {
      key: "labs",
      title: "Relevant Labs",
      body: render_labs_for_meds(patient),
      weight: 1.5
    }
  ]
end
```

### 3. Discharge Summary

**Purpose**: Generate a patient discharge summary

**Sections**:
- Admission reason
- Hospital course
- Procedures
- Discharge medications
- Follow-up instructions

```ruby
def discharge_sections(encounter)
  [
    {
      key: "admission",
      title: "Admission",
      body: render_admission(encounter),
      weight: 2.0
    },
    {
      key: "course",
      title: "Hospital Course",
      body: render_course(encounter),
      weight: 3.0
    },
    {
      key: "discharge_meds",
      title: "Discharge Medications",
      body: render_discharge_meds(encounter),
      weight: 3.0
    },
    {
      key: "followup",
      title: "Follow-up",
      body: render_followup(encounter),
      weight: 2.5
    }
  ]
end
```

## Intent-Aware PII Redaction

Different intents may have different PII requirements:

```ruby
class TenantPIIShield
  include GacsPack::Ports::PIIShield

  def redact(raw_context, role:, intent:)
    sections = raw_context[:sections].map do |section|
      apply_rules(section, role: role, intent: intent)
    end

    raw_context.merge(sections: sections)
  end

  private

  def apply_rules(section, role:, intent:)
    # Example: SSN only visible for billing intent
    if section[:key] == "ssn"
      return section.merge(body: "[REDACTED]") unless intent == "billing"
    end

    # Example: Full address only for care coordination
    if section[:key] == "address" && intent != "care_coordination"
      return section.merge(body: "[CITY, STATE ONLY]")
    end

    section
  end
end
```

## Defining Your Intents

1. **List your use cases**: What AI tasks do you need context for?
2. **Map to sections**: Which data sections are relevant?
3. **Assign priorities**: What's essential vs. nice-to-have?
4. **Define PII rules**: What can be shared for this intent?

### Example Intent Registry

```ruby
# config/initializers/gacs_pack_intents.rb
module GacsPack
  INTENTS = {
    "care_gap_analysis" => {
      description: "Identify preventive care gaps",
      priority_sections: ["conditions", "labs", "screenings"],
      pii_level: :standard
    },
    "medication_review" => {
      description: "Review medications for interactions",
      priority_sections: ["medications", "allergies"],
      pii_level: :standard
    },
    "discharge_summary" => {
      description: "Generate discharge summary",
      priority_sections: ["course", "discharge_meds", "followup"],
      pii_level: :full
    }
  }
end
```

## Testing Intents

```ruby
RSpec.describe "care_gap_analysis intent" do
  it "prioritizes conditions and labs" do
    adapter = PatientevityGraphAdapter.new

    result = adapter.build_context(
      subject_id: patient.id,
      subject_type: "Patient",
      intent: "care_gap_analysis",
      role: "provider"
    )

    weights = result[:sections].map { |s| [s[:key], s[:weight]] }.to_h

    expect(weights["conditions"]).to be > weights["demographics"]
    expect(weights["labs"]).to be > weights["demographics"]
  end
end
```

## Best Practices

1. **Use semantic names**: `"care_gap_analysis"` not `"intent_1"`
2. **Document each intent**: Purpose, sections, priorities
3. **Version your intents**: `"care_gap_v2"` when changing behavior
4. **Test with real AI calls**: Validate that context produces good outputs
5. **Monitor intent usage**: Track which intents are most common
