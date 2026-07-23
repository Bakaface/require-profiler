# frozen_string_literal: true

module RequireProfiler
  module Plugins
    # Track Rails initialization: railtie initializers, to_prepare callbacks, and load hooks
    class RailsPlugin < Base
      module InitializerPatch
        def run(...)
          RailsPlugin.track(:initializer, name, block) { super }
        end
      end

      module ToPreparePatch
        def to_prepare(*args, &block)
          return super unless block

          super do |*prepare_args|
            RailsPlugin.track(:to_prepare, nil, block) do
              instance_exec(*prepare_args, &block)
            end
          end
        end
      end

      module LoadHookPatch
        private

        def execute_hook(name, base, options, block)
          RailsPlugin.track(:load_hook, name, block) { super }
        end
      end

      class << self
        attr_accessor :reporter

        def track(kind, name, block)
          path = label(kind, name, block)
          reporter.handle_event(Reporter::Event.new(type: :start, kind: :rails, path:))
          start = Time.now
          yield
        ensure
          time = Time.now - start
          reporter.handle_event(Reporter::Event.new(type: :end, path:, time:))
        end

        def label(kind, name, block)
          ["rails:#{kind}", name, block&.source_location&.join(":")].compact.join(":")
        end
      end

      def activate!
        RailsPlugin.reporter = reporter

        Patcher.on_load("Rails::Initializable::Initializer") do
          ::Rails::Initializable::Initializer.prepend(InitializerPatch)
        end
        Patcher.on_load("ActiveSupport::Reloader") do
          ::ActiveSupport::Reloader.singleton_class.prepend(ToPreparePatch)
        end
        Patcher.on_load("ActiveSupport::LazyLoadHooks") do
          ::ActiveSupport.singleton_class.prepend(LoadHookPatch)
        end
      end
    end
  end
end
