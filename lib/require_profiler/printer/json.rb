# frozen_string_literal: true

require "json"

module RequireProfiler
  module Printer
    # JSON formatter converts call tacks into Speedscope
    # compatible JSON on finish.
    #
    # Can only be used with rewindable IO.
    class JSON < CallStack
      def finish
        output.rewind
        stacks = output.read
        output.rewind

        frames = []
        frame_index = {}

        samples = []
        weights = []

        stacks.each_line do |line|
          line = line.strip
          next if line.empty?

          sep = line.rindex(" ")
          next unless sep

          stack = line[0...sep]
          weight = line[(sep + 1)..].to_f

          sample = stack.split(";").map do |name|
            frame_index[name] ||= begin
              frames << {name: name}
              frames.size - 1
            end
          end

          samples << sample
          weights << weight
        end

        total = weights.sum

        profile = {
          "$schema" => "https://www.speedscope.app/file-format-schema.json",
          :shared => {frames: frames},
          :profiles => [
            {
              type: "sampled",
              unit: "milliseconds",
              startValue: 0,
              endValue: total,
              samples:,
              weights:
            }
          ]
        }

        output.write(::JSON.pretty_generate(profile))
        output.truncate(output.pos)
        super
      end
    end
  end
end
