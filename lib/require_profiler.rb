# frozen_string_literal: true

module RequireProfiler
  autoload :Reporter, "require_profiler/reporter"
  autoload :Printer, "require_profiler/printer"

  class << self
    attr_reader :reporter

    def start(output: $stdout, format: nil, patterns: nil, exclude_patterns: nil)
      raise ArgumentError, "There is already profiling in progress" if reporter

      reporter = @reporter = Reporter.new(printer: Printer.resolve(output, format))

      require "require-hooks/setup"

      ::RequireHooks.around_load(patterns:, exclude_patterns:) do |path, &block|
        start = Time.now

        reporter.handle_event(Reporter::Event.new(type: :start, path:))

        block.call
      ensure
        time = Time.now - start
        reporter.handle_event(Reporter::Event.new(type: :end, path:, time:))
      end
    end

    def stop
      raise "No reporter defined. Are you sure you called RequireProfiler.start?" unless reporter

      reporter.finish.tap do
        @reporter = nil
      end
    end
  end
end
