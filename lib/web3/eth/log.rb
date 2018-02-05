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

    def has_topics?
      !!topics.first
    end

    def method_hash
      topics.first && topics.first[2..65]
    end

    def indexed_args
      topics[1...topics.size].collect{|x| x[2..65]}
    end


  end

  end
end