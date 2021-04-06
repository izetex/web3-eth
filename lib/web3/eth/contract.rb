module Web3
  module Eth
    class Contract

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

        include Abi::AbiCoder
        include Abi::Utils
        include Utility

        attr_reader :abi, :signature, :name, :signature_hash, :input_types, :output_types, :constant

        def initialize abi
          @abi = abi
          @name = abi['name']
          @constant = !!abi['constant'] || abi['stateMutability']=='view'
          @input_types = abi['inputs'] ? abi['inputs'].map{|a| parse_component_type a } : []
          @output_types = abi['outputs'].map{|a| parse_component_type a } if abi['outputs']
          @signature = Abi::Utils.function_signature @name, @input_types
          @signature_hash = Abi::Utils.signature_hash @signature, (abi['type'].try(:downcase)=='event' ? 64 : 8)
        end

        def parse_component_type argument
          if argument['type']=~/^tuple((\[[0-9]*\])*)/
            argument['components'] ? "(#{argument['components'].collect{|c| parse_component_type c }.join(',')})#{$1}" : "()#{$1}"
          else
            argument['type']
          end
        end

        def parse_event_args log

          log_data = remove_0x_head log.raw_data['data']
          indexed_types = abi['inputs'].select{|a| a['indexed']}.collect{|a| parse_component_type a }
          not_indexed_types = abi['inputs'].select{|a| !a['indexed']}.collect{|a| parse_component_type a }

          indexed_args = log.indexed_args

          if indexed_args.size==indexed_types.size

            indexed_values = [indexed_types, indexed_args].transpose.collect{|arg|
              decode_typed_data( arg.first, [arg.second].pack('H*') )
            }

            not_indexed_values = not_indexed_types.empty? ? [] :
                                     decode_abi(not_indexed_types, [log_data].pack('H*') )

            i = j = 0

            abi['inputs'].collect{|input|
              input['indexed'] ? (i+=1; indexed_values[i-1]) : (j+=1;not_indexed_values[j-1])
            }

          elsif !indexed_args.empty? || !log_data.empty?
            all_types = abi['inputs'].collect{|a| parse_component_type a }
            [all_types[0...indexed_args.size], indexed_args].transpose.collect{|arg|
              decode_typed_data( arg.first, [arg.second].pack('H*') )
            } + decode_abi(all_types[indexed_args.size..-1], [log_data].pack('H*') )
          else
            []
          end

        end


        def parse_method_args transaction
          d = transaction.call_input_data
          (!d || d.empty?) ? [] : decode_abi(input_types, [d].pack('H*'))
        end

        def do_call web3_rpc, contract_address, args
          data = '0x' + signature_hash + encode_hex(encode_abi(input_types, args) )

          response = web3_rpc.eth.call [{ to: contract_address, data: data}, 'latest']

          string_data = [remove_0x_head(response)].pack('H*')
          return nil if string_data.empty?

          result = decode_abi output_types, string_data
          result.length==1 ? result.first : result
        end

      end

      class ContractConstructor < ContractMethod

        def initialize abi
          super abi
        end

        def parse_method_args transaction
          return [] if input_types.empty?

          input = transaction.input

          d = fetch_constructor_data input
          result = (d && !d.empty? && try_parse(d))

          unless result
            start = input.length-1-min_data_size(input_types)
            while start>=0 && !result
              result = try_parse input, start
              start -= 1
            end
          end

          result
        end

        private

        CONSTRUCTOR_SEQ = /a165627a7a72305820\w{64}0029(\w*)$/
        def fetch_constructor_data input
          data = input[CONSTRUCTOR_SEQ,1]
          while data && (d = data[CONSTRUCTOR_SEQ,1])
            data = d
          end
          data
        end

        def try_parse input, start = 0
          d = start==0  ? input : input.slice(start, input.length-start-1)
          decode_abi input_types, [d].pack('H*'), true
        rescue Exception => err
          nil
        end

      end


      attr_reader :web3_rpc, :abi, :functions, :events, :constructor, :functions_by_hash, :events_by_hash

      def initialize abi, web_rpc = nil
        @web3_rpc = web_rpc
        @abi = abi.kind_of?(String) ? JSON.parse(abi) : abi
        parse_abi @abi
      end

      def at address
        ContractInstance.new self, address
      end

      def call_contract contract_address, method_name, args
        function = functions[method_name]
        raise "No method found in ABI: #{method_name}" unless function
        raise "Function #{method_name} is not constant: #{method_name}, requires to sign transaction" unless function.constant
        function.do_call web3_rpc, contract_address, args
      end

      def find_event_by_hash method_hash
        @events_by_hash[method_hash]
      end

      def find_function_by_hash method_hash
        @functions_by_hash[method_hash]
      end

      def parse_log_args log
        event = find_event_by_hash log.method_hash
        raise "No event found by hash #{log.method_hash}, probably ABI is not related to log event" unless event
        event.parse_event_args log
      end

      def parse_call_args transaction
        function = find_function_by_hash transaction.method_hash
        raise "No function found by hash #{transaction.method_hash}, probably ABI is not related to call" unless function
        function.parse_method_args transaction
      end


      def parse_constructor_args transaction
        constructor ? constructor.parse_method_args(transaction) : []
      end

      private

      def parse_abi abi
        @functions = {}
        @events = {}

        @functions_by_hash = {}
        @events_by_hash = {}

        abi.each{|a|

          case a['type'].try(:downcase)
            when 'function'
              method = ContractMethod.new(a)
              @functions[method.name] = method
              @functions_by_hash[method.signature_hash] = method
            when 'event'
              method = ContractMethod.new(a)
              @events[method.name] = method
              @events_by_hash[method.signature_hash] = method
            when 'constructor'
              @constructor = ContractConstructor.new(a)
          end
        }
      end

    end
  end
end
