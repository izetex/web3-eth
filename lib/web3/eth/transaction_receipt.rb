module Web3
  module Eth

    class TransactionReceipt
      include Web3::Eth::Utility

      HEX_FIELDS = %w[block_number cumulative_gas_used gas_used status transaction_index].freeze

      attr_reader :raw_data

      def initialize transaction_data
        @raw_data = transaction_data

        @raw_data.each do |k, v|
          k = k.underscore
          if HEX_FIELDS.include? k
            self.instance_variable_set("@#{k}", from_hex(v))
          else
            self.instance_variable_set("@#{k}", v)
          end
          self.class.send(:define_method, k, proc {self.instance_variable_get("@#{k}")})
        end

        @logs = @logs.collect {|log|  Web3::Eth::Log.new log }

      end

      def success?
        status == 1 || status.nil?
      end

    end
  end
end
