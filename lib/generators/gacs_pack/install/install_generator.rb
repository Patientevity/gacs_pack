# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module GacsPack
  module Generators
    # Rails generator for installing gacs_pack
    #
    # Creates a migration for the context_packs table with:
    # - String primary key (context_pack_id)
    # - Tenant ID for multi-tenancy
    # - JSONB payload for snapshot data
    # - JSONB meta for metadata
    # - Timestamps
    #
    # Usage:
    #   rails generate gacs_pack:install
    #   rails db:migrate
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)
      desc "Creates a ContextPacks migration file"

      # Generates the migration file
      def create_migration_file
        migration_template(
          "create_context_packs.rb.erb",
          "db/migrate/create_context_packs.rb",
          migration_version: migration_version
        )
      end

      private

      # Returns the Rails migration version string
      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end
    end
  end
end
