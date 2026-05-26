# frozen_string_literal: true

module RequireProfiler
  module Plugins
    class << self
      def register_reporter(reporter)
        HTTPPlugin.new(reporter).activate! unless ENV["REQUIRE_PROFILER_HTTP"] == "false"
        YAMLPlugin.new(reporter).activate! unless ENV["REQUIRE_PROFILER_YAML"] == "false"
      end
    end

    class Base
      attr_reader :reporter

      def initialize(reporter)
        @reporter = reporter
      end
    end

    autoload :HTTPPlugin, "require_profiler/plugins/http_plugin"
    autoload :YAMLPlugin, "require_profiler/plugins/yaml_plugin"
  end
end
