# frozen_string_literal: true

module RequireProfiler
  module Printer
    # CallStack formatter prints collapsed stacks (Brendan Gregg's format)
    class CallStack < Base
      def flush(node, parts: [])
        return unless flush?(node)

        path = node.path.sub(prefix_stripper, "")
        self_parts = (node.kind == :path) ? path.split("/") : [path]

        parts += self_parts.size.times.map { self_parts.take(_1 + 1).join("/") }
        # We only show self-time, so exclude children
        val = ((node.time - node.children.sum(&:time)) * 1000).round(3)

        output << "#{parts.join(";")} #{val}\n"

        node.children.each { flush(_1, parts:) }
      end
    end
  end
end
