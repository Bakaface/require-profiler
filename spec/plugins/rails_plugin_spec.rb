# frozen_string_literal: true

RSpec.describe RequireProfiler::Plugins::RailsPlugin do
  it "captures Rails initialization: railtie initializers, to_prepare callbacks, and load hooks" do
    script = <<~RUBY
      require "stringio"
      io = StringIO.new

      RequireProfiler.start(
        output: io,
        patterns: ["#{fixtures_dir}/*.rb"]
      )

      require "integrations/rails"

      RequireProfiler.stop
      puts io.string
    RUBY

    stdout, stderr, status = run_profiler(script)

    expect(status).to be_success, "stderr: #{stderr}"
    expect(stdout).to include("integrations/rails.rb")
    expect(stdout).to match(%r{rails:initializer:.*rails\.rb:\d+.*\n.*leaf_a\.rb})
    expect(stdout).to match(%r{rails:to_prepare:.*rails\.rb:\d+.*\n.*leaf_b\.rb})
    expect(stdout).to match(%r{rails:load_hook:.*rails\.rb:\d+.*\n.*leaf_c\.rb})
  end
end
