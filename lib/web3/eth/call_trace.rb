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

      def value_wei
        from_hex action['value']
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
        action['input'] || action['init']
      end

      def output
        result && result['output']
      end

      def gas_used
        result && from_hex(result['gasUsed'])
      end

      def method_hash
        if input && input.length>=10
          input[2...10]
        else
          nil
        end
      end

      def creates
        action && result && action['init'] && result['address']
      end

      # suffix # 0xa1 0x65 'b' 'z' 'z' 'r' '0' 0x58 0x20 <32 bytes swarm hash> 0x00 0x29
      # look http://solidity.readthedocs.io/en/latest/metadata.html for details
      def call_input_data
        if creates && input
          input[/a165627a7a72305820\w{64}0029(\w*)/,1]
        elsif input && input.length>10
          input[10..input.length]
        else
          []
        end
      end


      def suicide?
        type=='suicide'
      end

      def balance_ether
        wei_to_ether action['balance'].to_i(16)
      end

      def success?
        !raw_data['error']
      end

    end
  end
end