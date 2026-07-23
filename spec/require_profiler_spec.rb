# frozen_string_literal: true

require "json"
require "tmpdir"

RSpec.describe RequireProfiler do
  it "captures all requires including gem loading when no filters are given" do
    script = <<~RUBY
      require "stringio"
      io = StringIO.new
      RequireProfiler.start(output: io)
      require "json"
      require "leaf_a"
      RequireProfiler.stop
      puts io.string
    RUBY

    stdout, stderr, status = run_profiler(script)

    expect(status).to be_success, "stderr: #{stderr}"
    expect(stdout).to include("leaf_a.rb")
    expect(stdout).to include("nested.rb")
    expect(stdout).to include("json.rb")
  end

  it "filters captured requires using patterns and exclude_patterns" do
    script = <<~RUBY
      require "stringio"
      io = StringIO.new
      RequireProfiler.start(
        output: io,
        patterns: ["#{fixtures_dir}/*.rb"],
        exclude_patterns: ["*/nested.rb"]
      )
      require "json"
      require "leaf_a"
      RequireProfiler.stop
      puts io.string
    RUBY

    stdout, stderr, status = run_profiler(script)

    expect(status).to be_success, "stderr: #{stderr}"
    expect(stdout).to include("leaf_a.rb")
    expect(stdout).not_to include("nested.rb")
    expect(stdout).not_to include("json.rb")
  end

  it "filters stacks by focus" do
    script = <<~RUBY
      require "stringio"
      io = StringIO.new
      RequireProfiler.start(
        output: io,
        focus: "leaf"
      )
      require "json"
      require "leaf_b"
      require "leaf_a"
      RequireProfiler.stop
      puts io.string
    RUBY

    stdout, stderr, status = run_profiler(script)

    expect(status).to be_success, "stderr: #{stderr}"
    expect(stdout).to include("leaf_a.rb")
    expect(stdout).to include("leaf_b.rb")
    expect(stdout).not_to include("json.rb")
    expect(stdout).not_to include("nested.rb")
  end

  it "prints a text report to $stdout when not output is defined" do
    script = <<~RUBY
      RequireProfiler.start
      require "leaf_a"
      RequireProfiler.stop
    RUBY

    stdout, stderr, status = run_profiler(script)

    expect(status).to be_success, "stderr: #{stderr}"
    expect(stdout).not_to be_empty
    expect(stdout).to include("leaf_a.rb")
    expect(stdout).to include("nested.rb")
    expect { JSON.parse(stdout) }.to raise_error(JSON::ParserError)
  end

  it "writes a Speedscope JSON report to a file path" do
    Dir.mktmpdir do |dir|
      report_path = File.join(dir, "require-report.json")

      script = <<~RUBY
        RequireProfiler.start(output: "#{report_path}")
        require "leaf_a"
        RequireProfiler.stop
      RUBY

      _stdout, stderr, status = run_profiler(script)

      expect(status).to be_success, "stderr: #{stderr}"
      expect(File).to exist(report_path)

      data = JSON.parse(File.read(report_path))

      expect(data).to include("$schema", "profiles", "shared")
      expect(data["shared"]).to include("frames")
      expect(data["shared"]["frames"]).to be_an(Array)
      expect(data["shared"]["frames"].last["name"]).to eq("spec/fixtures/nested.rb")
    end
  end

  it "does not leave trailing call-stack bytes when the JSON is shorter than the buffered stack" do
    Dir.mktmpdir do |dir|
      20.times do |i|
        File.write(File.join(dir, "leaf_#{i}.rb"), "require_relative 'leaf_#{(i + 1) % 20}'")
      end

      report_path = File.join(dir, "require-report.json")

      script = <<~RUBY
        RequireProfiler.start(output: "#{report_path}")
        require "#{dir}/leaf_0"
        RequireProfiler.stop
      RUBY

      _stdout, _stderr, _status = run_profiler(script)

      expect { JSON.parse(File.read(report_path)) }.not_to raise_error
    end
  end

  it "writes JSON to any IO when format: :json is given explicitly" do
    script = <<~RUBY
      require "stringio"
      io = StringIO.new
      RequireProfiler.start(output: io, format: :json)
      require "leaf_a"
      RequireProfiler.stop
      puts io.string
    RUBY

    stdout, stderr, status = run_profiler(script)

    expect(status).to be_success, "stderr: #{stderr}"
    data = JSON.parse(stdout)
    expect(data).to include("profiles", "shared")
  end

  context "integrations" do
    it "captures HTTP calls and YAML loading" do
      script = <<~RUBY
        require "yaml"
        require "net/http"

        require "stringio"
        io = StringIO.new

        RequireProfiler.start(
          output: io,
          patterns: ["#{fixtures_dir}/*.rb"]
        )

        require "integrations"

        RequireProfiler.stop
        puts io.string
      RUBY

      stdout, stderr, status = run_profiler(script)

      expect(status).to be_success, "stderr: #{stderr}"
      expect(stdout).to include("integrations.rb")
      expect(stdout).to include("integrations/http.rb")
      expect(stdout).to include("GET:http://ruby-lang.org")
      expect(stdout).to include("integrations/yaml.rb")
      expect(stdout).to include("config/data.yml")
    end

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
end
