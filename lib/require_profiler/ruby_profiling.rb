# frozen_string_literal: true

module RequireProfiler
  # This module contains helpers to activate specific files loading
  # profiling using Stackprof or Vernier (so you can dig deeper into why a particular
  # file is slow to require)
  module RubyProfiling
    class << self
      attr_accessor :enabled, :target_path, :profiler

      def enabled?
        @enabled
      end

      def capture(path, &)
        return yield unless path.end_with?(target_path)

        if profiler == :stackprof
          capture_stackprof(path, &)
        end
      end

      private

      def capture_stackprof(path)
        require "stackprof"

        filename = target_path.sub(/\.rb$/, "").tr("/.", "-") + "-stackprof"
        dump_path = filename + ".dump"

        options = {
          mode: :wall,
          raw: true,
          out: dump_path
        }

        ::StackProf.run(**options) { yield }.tap do
          report = ::StackProf::Report.new(
            Marshal.load(IO.binread(dump_path))
          )
          json_path = filename + ".json"
          File.write(json_path, JSON.generate(report.data))
          $stdout.puts "Stackprof JSON profile for #{target_path} is generated: #{json_path}"
        end
      end
    end

    if ENV["REQUIRE_PROFILE_STACKPROF"]
      self.enabled = true
      self.target_path = ENV["REQUIRE_PROFILE_STACKPROF"]
      self.profiler = :stackprof
    end
  end
end
