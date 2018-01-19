module Web3
  module Eth

    class TransactionReceipt

      include Web3::Eth::Utility

      attr_reader :raw_data

      def initialize transaction_data
        @raw_data = transaction_data

        transaction_data.each do |k, v|
          self.instance_variable_set("@#{k}", v)
          self.class.send(:define_method, k, proc {self.instance_variable_get("@#{k}")})
        end

        @logs = @logs.collect {|log|  Web3::Eth::Log.new log }

      end

      def block_number
        from_hex blockNumber
      end

      def success?
         status==1 || status=='0x1' || status.nil?
      end

      def gas_used
        from_hex gasUsed
      end


      def cumulative_gas_used
        from_hex cumulativeGasUsed
      end

    end
  end
end