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

    end

  end
end
