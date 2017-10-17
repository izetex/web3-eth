module Web3
  module Eth

    class Block

      include Web3::Eth::Utility

      def initialize block_data
        @block_data = block_data

        block_data.each do |k, v|
          next if self.respond_to? k.to_sym
          self.instance_variable_set("@#{k}", v)
          self.class.send(:define_method, k, proc {self.instance_variable_get("@#{k}")})
        end

        @transactions = block_data['transactions'].collect {|t|
          Transaction.new t
        }

      end

      def block_data
        @block_data
      end

      def timestamp_time
        Time.at from_hex timestamp
      end

    end

  end
end
