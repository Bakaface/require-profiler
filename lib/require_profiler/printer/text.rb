# frozen_string_literal: true

module RequireProfiler
  module Printer
    class Text < Base
      PAD = "  "

      def flush(node, indent: 0)
        return unless flush?(node)

        path = node.path.sub(prefix_stripper, "")
        output << "#{PAD * indent}#{path} — #{time_to_duration(node.time)}\n"
        node.children.each { flush(_1, indent: indent + 1) }

        output.flush
      end

      private

      # Converts seconds to human-readable milliseconds
      def time_to_duration(time) = "#{(time * 1000).round(3)}ms"
    end
  end
end
