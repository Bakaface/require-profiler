# frozen_string_literal: true

module RequireProfiler
  module Plugins
    # Track Rails initialization: railtie initializers, to_prepare callbacks, and load hooks
    class RailsPlugin < Base
      module InitializerPatch
        def self.apply!
          ::Rails::Initializable::Initializer.prepend(self) if defined?(::Rails::Initializable::Initializer)
        end

        def run(...)
          RailsPlugin.track(["initializer", name, RailsPlugin.location(block)].compact.join(":"), :initializer) { super }
        end
      end

      module ToPreparePatch
        def self.apply!
          ::ActiveSupport::Reloader.singleton_class.prepend(self) if defined?(::ActiveSupport::Reloader)
        end

        def to_prepare(*args, &block)
          return super unless block

          label = ["to_prepare", RailsPlugin.location(block)].compact.join(":")

          super do |*prepare_args|
            RailsPlugin.track(label, :to_prepare) do
              instance_exec(*prepare_args, &block)
            end
          end
        end
      end

      module LoadHookPatch
        def self.apply!
          ::ActiveSupport.singleton_class.prepend(self) if defined?(::ActiveSupport::LazyLoadHooks)
        end

        private

        def execute_hook(name, base, options, block)
          RailsPlugin.track(["load_hook", name, RailsPlugin.location(block)].compact.join(":"), :load_hook) { super }
        end
      end

      PATCHES = {
        "*/rails/initializable.rb" => InitializerPatch,
        "*/active_support/reloader.rb" => ToPreparePatch,
        "*/active_support/lazy_load_hooks.rb" => LoadHookPatch
      }.freeze

      class << self
        attr_accessor :reporter

        def track(path, kind)
          reporter.handle_event(Reporter::Event.new(type: :start, kind:, path:))
          start = Time.now
          yield
        ensure
          time = Time.now - start
          reporter.handle_event(Reporter::Event.new(type: :end, path:, time:))
        end

        def location(block)
          path = block&.source_location&.join(":")
          reporter.strip_prefix(path) if path
        end
      end

      def activate!
        RailsPlugin.reporter = reporter

        PATCHES.each_value(&:apply!)

        PATCHES.each do |pattern, patch|
          ::RequireHooks.around_load(patterns: [pattern]) do |_path, &block|
            block.call.tap { patch.apply! }
          end
        end
      end
    end
  end
end
