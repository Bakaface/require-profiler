# frozen_string_literal: true

module RequireProfiler
  module Printer
    # CallStack formatter prints collapsed stacks (Brendan Gregg's format)
    class CallStack < Base
      # Rails labels are "rails:#{type}:#{detail}", e.g. "rails:initializer:name:file:line"
      RAILS_LABEL_PARTS = 3
      RAILS_TYPE_INDEX = 1

      def flush(node, parts: [])
        return unless flush?(node)

        path = strip_prefix(node.path)
        self_parts =
          case node.kind
          when :rails then rails_frames(path)
          when :path then path_frames(path)
          else [path]
          end

        parts += self_parts
        # We only show self-time, so exclude children
        val = ((node.time - node.children.sum(&:time)) * 1000).round(3)

        output << "#{parts.join(";")} #{val}\n"

        node.children.each { flush(_1, parts:) }
      end

      private

      def rails_frames(path)
        ["rails:#{path.split(":", RAILS_LABEL_PARTS)[RAILS_TYPE_INDEX]}", path]
      end

      def path_frames(path)
        segments = path.split("/")
        segments.size.times.map { segments.take(_1 + 1).join("/") }
      end
    end
  end
end
