module Web3
  module Eth

    class CallTrace

      include Web3::Eth::Utility

      attr_reader :raw_data

      def initialize trace_data
        @raw_data = trace_data

        trace_data.each do |k, v|
          self.instance_variable_set("@#{k}", v)
          self.class.send(:define_method, k, proc {self.instance_variable_get("@#{k}")})
        end

      end

      def value_eth
        wei_to_ether from_hex action['value']
      end

      def from
        action['from']
      end

      def to
        action['to']
      end

      def input
        action['input']
      end

      def output
        result['output']
      end

    end
  end
end