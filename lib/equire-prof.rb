# frozen_string_literal: true

require "require_profiler"

RequireProfiler.start
at_exit { RequireProfiler.stop }
