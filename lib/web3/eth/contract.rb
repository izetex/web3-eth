module Web3
  module Eth
    class Contract

      include Abi::AbiCoder
      include Abi::Utils

      
      class ContractInstance

        def initialize contract, address
          @contract = contract
          @address = address
        end

        def method_missing m, *args
          @contract.call_contract @address, m.to_s, args
        end

      end

      attr_reader :web3_rpc, :abi, :functions, :events, :constructor

      def initialize web_rpc, abi
        @web3_rpc = web_rpc
        @abi = abi.kind_of?(String) ? JSON.parse(abi) : abi
        parse_abi abi
      end

      def at address
        ContractInstance.new self, address
      end

      def call_contract contract_address, method_name, args

        function = functions[method_name]
        raise "No method found in ABI: #{method_name}" unless function
        raise "Function #{method_name} is not constant: #{method_name}, require sign transaction" unless function['constant']

        arg_types = function['inputs'].map{|a| a['type']}
        return_types = function['outputs'].map{|a| a['type']}

        signature = "#{method_name}(#{arg_types.join(',')})"
        data = '0x' + encode_hex(keccak256(signature))[0..7] +
            encode_hex(encode_abi(arg_types, args) )

        response = web3_rpc.request "eth_call", [{ to: contract_address, data: data}]

        string_data = [remove_0x_head(response)].pack('H*')
        result = decode_abi return_types, string_data
        result.length==1 ? result.first : result

      end

      private

      def parse_abi abi
        @functions = Hash[abi.select{|a| a['type']=='function'}.map{|a| [a['name'], a]}]
        @events = Hash[abi.select{|a| a['type']=='event'}.map{|a| [a['name'], a]}]
        @constructor = abi.detect{|a| a['type']=='constructor'}
      end

    end
  end
end