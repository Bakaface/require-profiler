# frozen_string_literal: true

module RequireProfiler
  class Reporter
    class Event < Struct.new(:type, :path, :time, keyword_init: true)
    end

    class Node < Struct.new(:path, :time, :children, keyword_init: true)
      def initialize(...)
        super
        self.children ||= []
      end
    end

    private attr_reader :stack, :totals, :printer, :processor, :queue

    def initialize(printer:)
      @stack = []
      @totals = {count: 0, time: 0.0}
      @printer = printer
      @processor = nil
      @queue = Queue.new

      start_processor
    end

    def handle_event(event)
      queue << event
    end

    def handle_event_sync(event)
      if event.type == :start
        node = Node.new(path: event.path, children: [])
        stack.last&.children&.push(node)

        stack << node
      elsif event.type == :end
        last = stack.pop
        last.time = event.time

        printer.flush(last) if stack.empty?

        totals[:count] += 1
        totals[:time] += event.time if stack.empty?
      end
    end

    def finish
      handle_event(Event.new(type: :stop))
      processor.join

      warn "Finished in the middle of requiring a file" unless stack.empty?

      printer.finish
      totals
    end

    private

    def start_processor
      @processor = Thread.new do
        Thread.current.priority = -1

        loop do
          event = queue.pop

          break if event.type == :stop

          handle_event_sync(event)
        end
      end
    end
  end
end
