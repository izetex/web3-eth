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

      def unlockAccount(account, passphrase = '')
        @web3_rpc.request("#{PREFIX}#{__method__}", [account, passphrase])
      end
    end
  end
end
