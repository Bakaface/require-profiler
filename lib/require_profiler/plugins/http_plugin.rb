# frozen_string_literal: true

module RequireProfiler
  module Plugins
    # Track HTTP calls using Sniffer and add the to the require profile
    class HTTPPlugin < Base
      def activate!
        begin
          require "sniffer"
        rescue LoadError
          return
        end

        Sniffer.config.logger = Logger.new(IO::NULL)

        Sniffer.config.middleware do |chain|
          chain.add HTTPPlugin, reporter
        end

        Sniffer::DataItem::Request.include(Module.new do
          def require_path
            @url ||= "#{method.to_s.upcase}:#{(port == 443) ? "https" : "http"}://#{host}#{query}"
          end
        end)

        Sniffer.enable!
      end

      # Sniffer hook interface
      def request(data_item)
        reporter.handle_event(Reporter::Event.new(type: :start, path: data_item.request.require_path))
        yield
      end

      def response(data_item)
        yield
        time = data_item.response.timing
        reporter.handle_event(Reporter::Event.new(type: :end, path: data_item.request.require_path, time:))
      end
    end
  end
end
