module Web3
  module Eth

    class RpcError < RuntimeError
      attr_reader :code, :input, :response

      def initialize(message = '', code = nil, input = nil, response = nil)
        super(message)
        @code = code
        @input = input
        @response = response
      end
    end

    class Rpc

      require 'json'
      require 'net/http'

      JSON_RPC_VERSION = '2.0'

      DEFAULT_CONNECT_OPTIONS = {
          use_ssl: false,
          open_timeout: 10,
          read_timeout: 70
      }

      DEFAULT_HOST = 'localhost'
      DEFAULT_PORT = 8545

      attr_reader :eth, :personal, :trace

      def initialize host: DEFAULT_HOST, port: DEFAULT_PORT, connect_options: DEFAULT_CONNECT_OPTIONS

        @client_id = Random.rand 10000000

        @uri = URI((connect_options[:use_ssl] ? 'https' : 'http')+ "://#{host}:#{port}#{connect_options[:rpc_path]}")
        @connect_options = connect_options

        @eth = EthModule.new self
        @personal = PersonalModule.new self
        @trace = TraceModule.new self

      end


      def request method, params = nil


        Net::HTTP.start(@uri.host, @uri.port, @connect_options) do |http|

          request = Net::HTTP::Post.new @uri, {"Content-Type" => "application/json"}
          request.body = {:jsonrpc => JSON_RPC_VERSION, method: method, params: params, id: @client_id}.compact.to_json
          response = http.request request

          raise "Error code #{response.code} on request #{@uri.to_s} #{request.body}" unless response.kind_of? Net::HTTPOK

          body = JSON.parse(response.body)

          if body['result']
            body['result']
          elsif body['error']
            raise RpcError.new(body['error']['message'], body['error']['code'], request.body, body['error'])
          else
            raise RpcError.new("No response on request", -1, request.body, body)
          end

        end

      end
    end
  end
end

