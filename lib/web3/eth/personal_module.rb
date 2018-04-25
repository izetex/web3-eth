module Web3
  module Eth

    class PersonalModule

      include Web3::Eth::Utility

      PREFIX = 'personal_'.freeze

      def initialize(web3_rpc)
        @web3_rpc = web3_rpc
      end

      def newAccount(passphrase = '')
        @web3_rpc.request("#{PREFIX}#{__method__}", [passphrase])
      end

      def unlockAccount(account, passphrase = '', timeout = 30)
        @web3_rpc.request("#{PREFIX}#{__method__}", [account, passphrase, timeout])
      end

      # {from:, to:, value: (ether), gas:, gasPrice: (ether)}
      def sendTransaction(transaction, passphrase = '', convert_to_wei = true)
        transaction[:value]    = hex(convert_to_wei ? ether_to_wei(transaction[:value] || 0) : transaction[:value])
        transaction[:gas]      = hex(transaction[:gas]) if transaction[:gas]
        transaction[:gasPrice] = hex(convert_to_wei ? ether_to_wei(transaction[:gasPrice]) : transaction[:gasPrice]) if transaction[:gasPrice]

        @web3_rpc.request("#{PREFIX}#{__method__}", [transaction, passphrase])
      end
    end
  end
end
