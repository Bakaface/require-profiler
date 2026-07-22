# frozen_string_literal: true

module RequireProfiler
  module Printer
    class Base
      private attr_reader :output, :threshold, :focus
      private attr_reader :prefix_stripper

      def initialize(output, threshold: 0.0, focus: nil)
        @output = output
        @threshold = threshold
        @focus = focus

        # Identify prefixes for the project and the gems
        prefixes = [::Dir.pwd]
        prefixes << ::Gem.dir if defined?(::Gem.dir)
        prefixes << ::Bundler.bundle_path if defined?(::Bundler.bundle_path)

        @prefix_stripper = %r{^(#{prefixes.join("|")})/}
      end

      def strip_prefix(path)
        path.sub(prefix_stripper, "")
      end

      def flush(node)
        raise NotImplementedError
      end

      def finish
        output.close if output.respond_to?(:close) && output != $stdout
      end

      private

      def flush?(node)
        return false unless (node.time * 1000) >= threshold

        return false if focus && !node.focused

        true
      end
    end

    autoload :Text, "require_profiler/printer/text"
    autoload :CallStack, "require_profiler/printer/call_stack"
    autoload :JSON, "require_profiler/printer/json"

    class << self
      def resolve(output, format, **opts)
        format ||= (output.is_a?(String) && File.extname(output) == ".json") ? :json : :text
        output = File.open(output, "w+") if output.is_a?(String)

        case format.to_sym
        when :json then JSON.new(output, **opts)
        when :call_stack then CallStack.new(output, **opts)
        when :text then Text.new(output, **opts)
        else
          raise ArgumentError, "Unknown format specified: #{format}. Available formats: text, json, call_stack"
        end
      end
    end
  end
end
