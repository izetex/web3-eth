module Web3
  module Eth

    class Block
      include Web3::Eth::Utility

      HEX_FIELDS = %w[difficult gasLimit gasUsed nonce number size timestamp totalDifficulty].freeze

      attr_reader :raw_data, :block_hash

      def initialize block_data
        @raw_data = block_data
        @block_hash = block_data["hash"]

        block_data.each do |k, v|
          if HEX_FIELDS.include? k
            self.instance_variable_set("@#{k}", from_hex(v))
          else
            self.instance_variable_set("@#{k}", v)
          end
          self.class.send(:define_method, k, proc {self.instance_variable_get("@#{k}")})
        end
        @transactions = @transactions.collect {|t|  Web3::Eth::Transaction.new t }
      end

      def timestamp_time
        Time.at timestamp
      end
    end
  end
end
