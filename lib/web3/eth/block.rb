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
        from_hex difficulty
      end

      def block_gasLimit
        from_hex gasLimit
      end

      def block_gasUsed
        from_hex gasUsed
      end

      def block_nonce
        from_hex nonce
      end

      def block_size
        from_hex size
      end

      def block_totalDifficulty
        from_hex totalDifficulty
      end

    end

  end
end
