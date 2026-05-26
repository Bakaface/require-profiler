# frozen_string_literal: true

module RequireProfiler
  module Plugins
    # Track loading YAML files
    class YAMLPlugin < Base
      def activate!
        require "yaml"

        # TODO
      end
    end
  end
end
