module Web3
  module Eth

    class Block

      include Web3::Eth::Utility

      attr_reader :raw_data

      def initialize block_data
        @raw_data = block_data

        block_data.each do |k, v|
          self.instance_variable_set("@#{k}", v)
          self.class.send(:define_method, k, proc {self.instance_variable_get("@#{k}")})
        end

        @transactions = @transactions.collect {|t|  Web3::Eth::Transaction.new t }

      end

      def timestamp_time
        Time.at from_hex timestamp
      end

      def block_number
        from_hex number
      end

      def block_difficulty
        self.respond_to?(:difficulty) ? from_hex(difficulty) : 0
      end

      def block_gasLimit
        self.respond_to?(:gasLimit) ? from_hex(gasLimit) : 0
      end

      def block_gasUsed
        self.respond_to?(:gasUsed) ? from_hex(gasUsed) : 0
      end

      def block_nonce
        self.respond_to?(:nonce) ? from_hex(nonce) : 0
      end

      def block_size
        self.respond_to?(:size) ?  from_hex(size) : 0
      end

      def block_totalDifficulty
        self.respond_to?(:totalDifficulty) ? from_hex(totalDifficulty) : 0
      end

    end

  end
end
