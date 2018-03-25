module Web3
  module Eth

    class Transaction
      include Web3::Eth::Utility

      HEX_FIELDS = %w[gas gas_price nonce transaction_index value block_number].freeze

      attr_reader :raw_data

      def initialize(transaction_data)
        @raw_data = transaction_data
        transaction_data.each do |k, v|
          k = k.underscore
          if HEX_FIELDS.include? k
            self.instance_variable_set("@#{k}", from_hex(v))
          else
            self.instance_variable_set("@#{k}", v)
          end
          self.class.send(:define_method, k, proc {self.instance_variable_get("@#{k}")})
        end
      end

      def method_hash
        if input && input.length>=10
          input[2...10]
        else
          nil
        end
      end

      # suffix # 0xa1 0x65 'b' 'z' 'z' 'r' '0' 0x58 0x20 <32 bytes swarm hash> 0x00 0x29
      # look http://solidity.readthedocs.io/en/latest/metadata.html for details
      def call_input_data
        if raw_data['creates'] && input
          fetch_constructor_data input
        elsif input && input.length>10
          input[10..input.length]
        else
          []
        end
      end

      def value_eth
        wei_to_ether value
      end

      def gas_price_eth
        wei_to_ether gas_price
      end

      private

      CONSTRUCTOR_SEQ = /a165627a7a72305820\w{64}0029(\w*)$/
      def fetch_constructor_data input
        data = input[CONSTRUCTOR_SEQ,1]
        while data && (d = data[CONSTRUCTOR_SEQ,1])
          data = d
        end
        data
      end

    end
  end
end
