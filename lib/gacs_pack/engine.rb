# frozen_string_literal: true

require "rails/engine"

module GacsPack
  class Engine < ::Rails::Engine
    initializer "gacs_pack.assets" do |app|
      # Make the gem's lib/ available to the Rails asset pipeline
      app.config.assets.paths << root.join("lib").to_s

      # If Sprockets is present (Rails assets), ensure PNG is precompiled in production
      if app.config.respond_to?(:assets) && app.config.assets.respond_to?(:precompile)
        app.config.assets.precompile += ["gacso.png"]
      end
    end
  end
end
