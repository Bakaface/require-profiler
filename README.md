[![Gem Version](https://badge.fury.io/rb/require-profiler.svg)](https://rubygems.org/gems/require-profiler)
[![Build](https://github.com/palkan/require-profiler/workflows/Build/badge.svg)](https://github.com/palkan/require-profiler/actions)

# Require Profiler

Require Profiler is a tool for profiling Ruby's code loading—`Kernel#require`, `Kernel#require_relative`, and `Kernel#load`. It captures the call tree, measures how long each file takes to load, and can export the results as a [Speedscope][speedscope]-compatible JSON profile.

It's built on top of [Require Hooks][require-hooks], so it works anywhere Require Hooks does (MRI/JRuby/TruffleRuby).

<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

## Installation

Add to your Gemfile:

```ruby
gem "require-profiler"
```

### Supported Ruby versions

- Ruby (MRI) >= 3.1

## Usage

### Using `-require-prof` command switch

Given that `require-profiler` is a part of your bundle (or available globally), you can enable it as follows:

```sh
# Without Bundler
ruby -require-prof some_ruby_script.rb

# With Bundler
ruby -rbundler/setup -require-prof some_ruby_script.rb
```

For Rails applications, the command will look like:

```sh
bundle exec ruby -r./config/boot -require-prof config/environment.rb
```

We load the `config/boot.rb` file first to set up Bundler and **Bootsnap** (it must be required before require-hooks).

You can use environment variables to specify the output format and path. For example:

```sh
REQUIRE_PROFILE_PATH=tmp/require-prof.json bundle exec ruby -r./config/boot -require-prof config/environment.rb
```

You can also specify the threshold to display only files taking at least the provided number of milliseconds to load:

```sh
REQUIRE_PROFILE_THRESHOLD=100 bundle exec ruby -r./config/boot -require-prof config/environment.rb
```

Or file matching the provided _focus_ pattern:

```sh
REQUIRE_PROFILE_FOCUS=stripe bundle exec ruby -r./config/boot -require-prof config/environment.rb
```

### Programmable usage

If you code loading process is more complicated, you can manually start and stop the profiler from your application.

Wrap the code you want to profile with `RequireProfiler.start` and `RequireProfiler.stop`:

```ruby
require "require_profiler"

RequireProfiler.start(output: "path/to/profile.txt")
require "my_app"
RequireProfiler.stop
```

Only `require`/`load` calls that happen between `.start` and `.stop` are captured. Put `.start` as early as possible (e.g., at the top of `config/boot.rb` or an entry-point script) to see the full loading tree.

`RequireProfiler.stop` returns a totals hash: `{count: <number of files loaded>, time: <seconds>}`.

### Scoping via patterns

Use `patterns:` and `exclude_patterns:` to limit what gets profiled. Both accept globs as recognized by [`File.fnmatch`](https://rubyapi.org/4.0/o/file#method-c-fnmatch) and are passed through to Require Hooks:

```ruby
RequireProfiler.start(
  patterns: ["#{Dir.pwd}/app/**/*.rb", "#{Dir.pwd}/lib/**/*.rb"],
  exclude_patterns: ["*/vendor/*"]
)
```

### Ruby profilers integration

Whenever you identified the files that take a long time to load, it's useful to look at them closer and profile the load process using some generic profiler. Require Profiler simplifies this down to the environment variable usage. This is, for example, how you can profile the loading of an initializer file via StackProf:

```sh
$ REQUIRE_PROFILE_STACKPROF=config/initializers/fragment.rb REQUIRE_PROFILE_THRESHOLD=100 be ruby -r./config/boot -require-prof config/environment.rb

...
Stackprof JSON profile for config/initializers/fragment.rb is generated: config-initializers-fragment-stackprof.json
...

```

Now you can use Speedscope to dig deeper.

**NOTE:** The `stackprof` gem must be present in your Gemfile for that.

### Configuration

`RequireProfiler.start` accepts the following keyword arguments:

- `output:` — `$stdout` (default), any IO-like object, or a file path (string).
- `format:` — `:text` (default), `:call_stack`, or `:json`. When `output:` is a file path with a `.json` extension, the JSON format is picked automatically. You can also provide format via the `REQUIRE_PROFILE_FORMAT` env var.
- `threshold:` — the number of **milliseconds** to use as a threshold to ignore files taking less to load, float. Default is 0.0
- `patterns:` / `exclude_patterns:` — see above.

## Output formats

### Text (default)

A human-readable indented tree, one line per file, with self+children duration in milliseconds:

```
lib/my_app.rb — 42.137ms
  lib/my_app/config.rb — 3.211ms
  lib/my_app/router.rb — 12.004ms
    lib/my_app/routes.rb — 9.882ms
```

Paths are printed relative to `Dir.pwd`, `Gem.dir`, or `Bundler.bundle_path` when they match—so vendored gem loads stay readable.

### Collapsed call stacks

```ruby
RequireProfiler.start(output: "tmp/require-profile.txt", format: :call_stack)
```

Emits one line per stack in [Brendan Gregg's collapsed format](https://github.com/brendangregg/FlameGraph#2-fold-stacks) with per-frame self time in milliseconds. Pipe it to `flamegraph.pl`, [`inferno`](https://github.com/jonhoo/inferno), or any tool that consumes folded stacks.

### JSON / Speedscope

```ruby
RequireProfiler.start(output: "tmp/require-profile.json")
# or:
RequireProfiler.start(output: io, format: :json)
```

Emits a profile that conforms to the [Speedscope file format schema](https://www.speedscope.app/file-format-schema.json).

**Note:** Writing JSON straight to `$stdout` is not supported.

## Using with Speedscope

[Speedscope][speedscope] is an interactive flamegraph viewer that runs entirely in your browser (nothing is uploaded—the file is parsed locally).

1. Generate a JSON profile:

   ```ruby
   RequireProfiler.start(output: "tmp/require-profile.json")
   require "my_app"
   RequireProfiler.stop
   ```

2. Open [https://www.speedscope.app/](https://www.speedscope.app/) and drag-and-drop `tmp/require-profile.json` onto the page (or use the "Browse" button).

3. Switch to the **Left Heavy** view to see which `require` chains cost the most time, and use **Sandwich** view to find individual files that show up repeatedly.

Prefer to stay local? Install the CLI and it will open a local viewer for you:

```sh
npm install -g speedscope
speedscope tmp/require-profile.json
```

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/palkan/require-profiler](https://github.com/palkan/require-profiler).

## Credits

This gem is generated via [`newgem` template](https://github.com/palkan/newgem) by [@palkan](https://github.com/palkan).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[speedscope]: https://www.speedscope.app/
[require-hooks]: https://github.com/ruby-next/require-hooks
