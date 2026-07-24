# frozen_string_literal: true

require "open3"

module ProfilerRunner
  ROOT = File.expand_path("../..", __dir__)
  FIXTURES_DIR = File.join(ROOT, "spec", "fixtures")

  def run_profiler(script)
    Open3.capture3(
      RbConfig.ruby,
      "-I", File.join(ROOT, "lib"),
      "-I", FIXTURES_DIR,
      "-r", "bundler/setup",
      "-r", "require-profiler",
      "-e", script
    )
  end

  def fixtures_dir
    FIXTURES_DIR
  end
end

RSpec.configure do |config|
  config.include ProfilerRunner
end
