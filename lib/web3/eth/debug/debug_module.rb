module Web3::Eth::Debug

    class DebugModule

      include Web3::Eth::Utility

      PREFIX = 'debug_'

      def initialize web3_rpc
        @web3_rpc = web3_rpc
      end

      def traceTransaction hash, tracer = 'callTracer',  convert_to_object = true
        raw = @web3_rpc.request("#{PREFIX}#{__method__}", [hash, {tracer: tracer}])
        convert_to_object ? TransactionCallTrace.new(raw) : raw
      end

      def traceBlockByNumber number, tracer = 'callTracer',  convert_to_object = true
        raw = @web3_rpc.request("#{PREFIX}#{__method__}", [hex(number), {tracer: tracer}])
        convert_to_object ? raw.map{|r| TransactionCallTrace.new(r['result'])} : raw
      end

      def traceBlockByHash hash, tracer = 'callTracer',  convert_to_object = true
        raw = @web3_rpc.request("#{PREFIX}#{__method__}", [hash, {tracer: tracer}])
        convert_to_object ? raw.map{|r| TransactionCallTrace.new(r['result'])} : raw
      end


      def method_missing m, *args
        @web3_rpc.request "#{PREFIX}#{m}", args[0]
      end


    end

end
