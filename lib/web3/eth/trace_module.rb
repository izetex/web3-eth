module Web3
  module Eth

    class TraceModule

      include Web3::Eth::Utility

      PREFIX = 'trace_'

      def initialize web3_rpc
        @web3_rpc = web3_rpc
      end

      def method_missing m, *args
        @web3_rpc.request "#{PREFIX}#{m}", args[0]
      end

      def internalCallsByHash tx_hash
        @web3_rpc.request("#{PREFIX}transaction", [tx_hash]).select{|t| t['traceAddress']!=[]}.collect{|t|
          CallTrace.new t
        }
      end

    end
  end
end
