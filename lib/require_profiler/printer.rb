# frozen_string_literal: true

module RequireProfiler
  module Printer
    class Base
      private attr_reader :output
      private attr_reader :prefix_stripper

      def initialize(output)
        @output = output

        # Identify prefixes for the project and the gems
        prefixes = [::Dir.pwd]
        prefixes << ::Gem.dir if defined?(::Gem.dir)
        prefixes << ::Bundler.bundle_path if defined?(::Bundler.bundle_path)

        @prefix_stripper = %r{^(#{prefixes.join("|")})/}
      end

      def flush(node)
        raise NotImplementedError
      end

      def finish
        output.close if output.respond_to?(:close) && output != $stdout
      end
    end

    autoload :Text, "require_profiler/printer/text"
    autoload :CallStack, "require_profiler/printer/call_stack"
    autoload :JSON, "require_profiler/printer/json"

    class << self
      def resolve(output, format)
        format ||= (output.is_a?(String) && File.extname(output) == ".json") ? :json : :text
        output = File.open(output, "w+") if output.is_a?(String)

        case format.to_sym
        when :json then JSON.new(output)
        when :call_stack then CallStack.new(output)
        when :text then Text.new(output)
        else
          raise ArgumentError, "Unknown format specified: #{format}. Available formats: text, json, call_stack"
        end
      end
    end
  end
end
