# frozen_string_literal: true

RSpec.describe RequireProfiler::Plugins::HTTPPlugin do
  it "captures HTTP calls" do
    script = <<~RUBY
      require "net/http"

      require "stringio"
      io = StringIO.new

      RequireProfiler.start(
        output: io,
        patterns: ["#{fixtures_dir}/*.rb"]
      )

      require "integrations/http"

      RequireProfiler.stop
      puts io.string
    RUBY

    stdout, stderr, status = run_profiler(script)

    expect(status).to be_success, "stderr: #{stderr}"
    expect(stdout).to include("integrations/http.rb")
    expect(stdout).to include("GET:http://ruby-lang.org")
  end
end
