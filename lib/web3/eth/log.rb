module Web3
  module Eth

  class Log

    attr_reader :raw_data

    def initialize log
      @raw_data = log

      log.each do |k, v|
        self.instance_variable_set("@#{k}", v)
        self.class.send(:define_method, k, proc {self.instance_variable_get("@#{k}")})
      end

    end


    def method_hash
      topics.first
    end

    def indexed_args
      topics[1...topics.size]
    end


  end

  end
end