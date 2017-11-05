module Web3
  module Eth

    class EthModule

      include Web3::Eth::Utility

      PREFIX = 'eth_'

      def initialize web3_rpc
        @web3_rpc = web3_rpc
      end

      def getBalance address, block = 'latest', convert_to_eth = true
        wei = @web3_rpc.request("#{PREFIX}#{__method__}", [address, block]).to_i 16
        convert_to_eth ? wei_to_ether(wei) : wei
      end

      def getBlockByNumber block, full = true, convert_to_object = true
        resp = @web3_rpc.request("#{PREFIX}#{__method__}", [hex(block), full])
        convert_to_object ? Block.new(resp) : resp
      end

      def blockNumber
        from_hex @web3_rpc.request("#{PREFIX}#{__method__}")
      end

      def getTransactionByHash tx_hash
        Transaction.new @web3_rpc.request("#{PREFIX}#{__method__}", [tx_hash])
      end

      def getTransactionReceipt tx_hash
        TransactionReceipt.new @web3_rpc.request("#{PREFIX}#{__method__}", [tx_hash])
      end

      def contract abi
        Web3::Eth::Contract.new abi, @web3_rpc
      end

      def load_contract etherscan_api, contract_address
        contract(etherscan_api.contract_getabi address: contract_address).at contract_address
      end


      def method_missing m, *args
        @web3_rpc.request "#{PREFIX}#{m}", args[0]
      end


    end
  end
end
