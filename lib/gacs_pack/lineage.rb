# frozen_string_literal: true

module GacsPack
  # Lineage tracks provenance information across context pack sections.
  #
  # Each section may contain a :lineage array that traces back through
  # the knowledge graph. This class aggregates lineage from all sections
  # to provide a complete provenance trail.
  #
  # @example Extracting lineage from sections
  #   sections = [
  #     { key: "demographics", lineage: ["patient:123", "demographics"] },
  #     { key: "conditions", lineage: ["patient:123", "conditions", "icd10:E11"] }
  #   ]
  #
  #   lineage = GacsPack::Lineage.from(sections)
  #   # => ["patient:123", "demographics", "conditions", "icd10:E11"]
  class Lineage
    # Extracts and aggregates unique lineage entries from sections
    #
    # @param sections [Array<Hash>] Array of section hashes
    #
    # @return [Array<String>] Unique lineage entries across all sections
    def self.from(sections)
      return [] if sections.nil? || sections.empty?

      sections
        .flat_map { |section| Array(section[:lineage]) }
        .uniq
    end
  end
end
