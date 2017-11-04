module Web3
  module Eth
    class Contract

      include Abi::AbiCoder
      include Abi::Utils
      include Utility

      
      class ContractInstance

        def initialize contract, address
          @contract = contract
          @address = address
        end

        def method_missing m, *args
          @contract.call_contract @address, m.to_s, args
        end

        def __contract__
          @contract
        end

        def __address__
          @address
        end

      end

      class ContractMethod
        attr_reader :abi, :signature, :name, :signature_hash, :input_types, :output_types, :constant

        def initialize abi
          @abi = abi
          @name = abi['name']
          @constant = !!abi['constant']
          @input_types = abi['inputs'].map{|a| a['type']}
          @output_types = abi['outputs'].map{|a| a['type']} if abi['outputs']
          @signature = Abi::Utils.function_signature @name, @input_types
          @signature_hash = Abi::Utils.signature_hash @signature, (abi['type']=='event' ? 64 : 8)
        end

      end

      attr_reader :web3_rpc, :abi, :functions, :events, :constructor

      def initialize abi, web_rpc = nil
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
        raise "Function #{method_name} is not constant: #{method_name}, requires to sign transaction" unless function.constant

        data = '0x' + function.signature_hash + encode_hex(encode_abi(function.input_types, args) )

        response = web3_rpc.request "eth_call", [{ to: contract_address, data: data}]

        string_data = [remove_0x_head(response)].pack('H*')
        result = decode_abi function.output_types, string_data
        result.length==1 ? result.first : result

      end

      def find_event_by_hash method_hash
        events.values.detect{|e| e.signature_hash==method_hash}
      end

      def find_function_by_hash method_hash
        functions.values.detect{|e| e.signature_hash==method_hash}
      end

      def parse_log_args log

        event = find_event_by_hash log.method_hash
        raise "No event found by hash #{log.method_hash}, probably ABI is not related to log event" unless event

        not_indexed_types = event.abi['inputs'].select{|a| !a['indexed']}.collect{|a| a['type']}
        not_indexed_values = not_indexed_types.empty? ? [] :
                             decode_abi(not_indexed_types, [remove_0x_head(log.raw_data['data'])].pack('H*') )

        indexed_types = event.abi['inputs'].select{|a| a['indexed']}.collect{|a| a['type']}
        indexed_values = [indexed_types, log.indexed_args].transpose.collect{|arg|
          decode_abi([arg.first], [arg.second].pack('H*') ).first
        }

        i = j = 0

        event.abi['inputs'].collect{|input|
          input['indexed'] ? (i+=1; indexed_values[i-1]) : (j+=1;not_indexed_values[j-1])
        }

      end

      def parse_call_args transaction
        function = find_function_by_hash transaction.method_hash
        raise "No function found by hash #{transaction.method_hash}, probably ABI is not related to call" unless function
        [function.input_types, transaction.method_arguments].transpose.collect{|arg|
          decode_abi([arg.first], [arg.second].pack('H*') ).first
        }
      end


      def parse_constructor_args transaction
        # suffix # 0xa1 0x65 'b' 'z' 'z' 'r' '0' 0x58 0x20 <32 bytes swarm hash> 0x00 0x29
        # look http://solidity.readthedocs.io/en/latest/metadata.html for details
        args = transaction.input[/a165627a7a72305820\w{64}0029(\w*)/,1]
        args ? decode_abi(constructor.input_types, [args].pack('H*') ) : []
      end

      private

      def parse_abi abi
        @functions = Hash[abi.select{|a| a['type']=='function'}.map{|a| [a['name'], ContractMethod.new(a)]}]
        @events = Hash[abi.select{|a| a['type']=='event'}.map{|a| [a['name'], ContractMethod.new(a)]}]
        @constructor = ContractMethod.new abi.detect{|a| a['type']=='constructor'}
      end

    end
  end
end