# frozen_string_literal: true

module RequireProfiler
  autoload :Reporter, "require_profiler/reporter"
  autoload :Printer, "require_profiler/printer"
  autoload :Plugins, "require_profiler/plugins"

  # Autoload doesn't work here, because we call it from the hooks for the first time
  require "require_profiler/ruby_profiling"

  class << self
    attr_reader :reporter

    def start(
      output: ENV.fetch("REQUIRE_PROFILE_PATH", $stdout),
      format: ENV["REQUIRE_PROFILE_FORMAT"],
      threshold: ENV.fetch("REQUIRE_PROFILE_THRESHOLD", "0.0").to_f,
      focus: ENV["REQUIRE_PROFILE_FOCUS"],
      patterns: nil, exclude_patterns: nil
    )
      raise ArgumentError, "There is already profiling in progress" if reporter

      focus = Regexp.new(focus) if focus.is_a?(String)
      reporter = @reporter = Reporter.new(printer: Printer.resolve(output, format, threshold:, focus:), focus:)

      require "require-hooks/setup"

      ::RequireHooks.around_load(patterns:, exclude_patterns:) do |path, &block|
        start = Time.now

        reporter.handle_event(Reporter::Event.new(type: :start, path:))

        if RubyProfiling.enabled?
          RubyProfiling.capture(path) { block.call }
        else
          block.call
        end
      ensure
        time = Time.now - start
        reporter.handle_event(Reporter::Event.new(type: :end, path:, time:))
      end

      Plugins.register_reporter(reporter) unless ENV["REQUIRE_PROFILER_PLUGINS"] == "false"
    end

    def stop
      raise "No reporter defined. Are you sure you called RequireProfiler.start?" unless reporter

      reporter.finish.tap do
        @reporter = nil
      end
    end
  end
end
