# frozen_string_literal: true

module RequireProfiler
  module Plugins
    # Track loading YAML files
    class YAMLPlugin < Base
      module Patch
        def load_file(path, ...)
          YAMLPlugin.track(path) { super }
        end

        def unsafe_load_file(path, ...)
          YAMLPlugin.track(path) { super }
        end

        def safe_load_file(path, ...)
          YAMLPlugin.track(path) { super }
        end
      end

      class << self
        attr_accessor :reporter

        def track(path)
          reporter.handle_event(Reporter::Event.new(type: :start, kind: :yml, path:))
          start = Time.now
          yield
        ensure
          time = Time.now - start
          reporter.handle_event(Reporter::Event.new(type: :end, path:, time:))
        end
      end

      def activate!
        require "yaml"

        YAMLPlugin.reporter = reporter
        ::YAML.singleton_class.prepend(Patch)
      end
    end
  end
end
