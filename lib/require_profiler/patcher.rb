# frozen_string_literal: true

module RequireProfiler
  # Use TracePoint to run a callback when a particular class is defined
  module Patcher
    class << self
      def on_load(name, &callback)
        return callback.call if Object.const_defined?(name)

        callbacks[name] = callback

        tracer.enable
      end

      private

      def callbacks = @callbacks ||= {}

      def tracer = @tracer ||= TracePoint.new(:end, &method(:on_class))

      def name_method = @name_method ||= Module.instance_method(:name)

      def on_class(event)
        return if event.self.singleton_class?

        class_name = name_method.bind_call(event.self)
        return unless callbacks[class_name]

        callback = callbacks.delete(class_name)
        tracer.disable if callbacks.empty?

        callback.call
      end
    end
  end
end
