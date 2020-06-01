module Web3
  module Eth

    class ParityModule

      include Web3::Eth::Utility

      PREFIX = 'parity_'

      def initialize web3_rpc
        @web3_rpc = web3_rpc
      end

      def method_missing m, *args
        @web3_rpc.request "#{PREFIX}#{m}", args[0]
      end

      def getBlockReceiptsByBlockNumber block
        @web3_rpc.request("#{PREFIX}getBlockReceipts", [hex(block)]).collect{|tr|
          TransactionReceipt.new tr
        }
      end

    end
  end
end
