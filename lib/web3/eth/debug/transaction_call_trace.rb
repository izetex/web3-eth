module Web3::Eth::Debug

    class TransactionCallTrace

      include Web3::Eth::Utility

      attr_reader :raw_data, :calls, :traceAddress, :parent
      def initialize raw, traceAddress = [], parent = nil
        @raw_data = raw
        @traceAddress = traceAddress
        @parent = parent
        @calls = raw['calls'] ? raw['calls'].each_with_index.map{|c,i| TransactionCallTrace.new c, (traceAddress + [i]), parent } : []
      end

      # CALL STATICCALL DELEGATECALL CREATE SELFDESTRUCT
      def type
        raw_data['type']
      end

      def action
        {
            'callType' => type.downcase,
            'address' => ( suicide? ? parent.smart_contract : raw_data['to'])
        }
      end

      def smart_contract
        ['DELEGATECALL','CALL'].include?(type) ? to : from
      end

      def creates
        (type=='CREATE' || type=='CREATE2') ? to : nil
      end

      def method_hash
        if input && input.length>=10
          input[2...10]
        else
          nil
        end
      end

      def suicide?
        type=='SELFDESTRUCT'
      end

      def from
        raw_data['from']
      end

      def to
        raw_data['to']
      end

      def value_wei
        from_hex raw_data['value']
      end

      def value_eth
        wei_to_ether value_wei
      end

      def gas
        from_hex raw_data['gas']
      end

      def gas_used
        from_hex raw_data['gasUsed']
      end

      def input
        raw_data['input']
      end

      def output
        raw_data['output']
      end

      def time
        raw_data['time']
      end

      def error
        raw_data['error']
      end

      def success?
        !raw_data['error']
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

    end


end
