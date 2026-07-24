# frozen_string_literal: true

RSpec.describe RequireProfiler::Plugins::YAMLPlugin do
  it "captures YAML loading" do
    script = <<~RUBY
      require "yaml"

      require "stringio"
      io = StringIO.new

      RequireProfiler.start(
        output: io,
        patterns: ["#{fixtures_dir}/*.rb"]
      )

      require "integrations/yaml"

      RequireProfiler.stop
      puts io.string
    RUBY

    stdout, stderr, status = run_profiler(script)

    expect(status).to be_success, "stderr: #{stderr}"
    expect(stdout).to include("integrations/yaml.rb")
    expect(stdout).to include("config/data.yml")
  end
end
