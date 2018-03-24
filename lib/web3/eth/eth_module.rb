module Web3
  module Eth

    class EthModule

      include Web3::Eth::Utility

      PREFIX = 'eth_'.freeze

      def initialize(web3_rpc)
        @web3_rpc = web3_rpc
      end

      def getBalance(address, block = 'latest', convert_to_eth = true)
        wei = @web3_rpc.request("#{PREFIX}#{__method__}", [address, block])
        wei = from_hex(wei)
        convert_to_eth ? wei_to_ether(wei) : wei
      end

      def getBlockByNumber(block, full = true, convert_to_object = true)
        resp = @web3_rpc.request("#{PREFIX}#{__method__}", [hex(block), full])
        convert_to_object ? Block.new(resp) : resp.deep_symbolize_keys
      end

      def blockNumber
        from_hex(@web3_rpc.request("#{PREFIX}#{__method__}"))
      end

      def getTransaction(tx_hash, convert_to_object = true)
        resp = @web3_rpc.request("#{PREFIX}#{__method__}ByHash", [tx_hash])
        convert_to_object ? Transaction.new(resp) : resp.deep_symbolize_keys
      end

      def getTransactionReceipt(tx_hash, convert_to_object = true)
        resp = @web3_rpc.request("#{PREFIX}#{__method__}", [tx_hash])
        convert_to_object ? TransactionReceipt.new(resp) : resp.deep_symbolize_keys
      end

      def gasPrice(convert_to_eth = true)
        wei = @web3_rpc.request("#{PREFIX}#{__method__}", [])
        wei = from_hex(wei)
        convert_to_eth ? wei_to_ether(wei) : wei
      end

      # array of hashes {from:, to:, value: (wei), gas:}
      def sendTransaction(transactions = [], convert_to_wei = true)
        transactions = Array(transactions)
        transactions.each do |t|
          t[:value]    = hex(convert_to_wei ? ether_to_wei(t[:value] || 0) : t[:value])
          t[:gas]      = hex(t[:gas]) if t[:gas]
          t[:gasPrice] = hex(convert_to_wei ? ether_to_wei(t[:gasPrice]) : t[:gasPrice]) if t[:gasPrice]
        end
        @web3_rpc.request("#{PREFIX}#{__method__}", transactions)
      end

      def contract(abi)
        Web3::Eth::Contract.new(abi, @web3_rpc)
      end

      def load_contract(etherscan_api, contract_address)
        contract(etherscan_api.contract_getabi address: contract_address).at contract_address
      end

      def method_missing(m, *args)
        @web3_rpc.request("#{PREFIX}#{m}", args || [])
      end

    end
  end
end
