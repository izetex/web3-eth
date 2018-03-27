unless Hash.method_defined?(:compact)
  class Hash
    def compact
      self.reject{ |_k, v| v.nil? }
    end
  end
end

unless Hash.method_defined?(:deep_symbolize_keys)
  class Hash
    def deep_symbolize_keys
      symbolize_keys(self)
    end

    private def symbolize_keys(hash)
      hash.inject({}){|result, (key, value)|
        new_key = case key
                  when String then key.to_sym
                  else key
                  end
        new_value = case value
                    when Hash then symbolize_keys(value)
                    else value
                    end
        result[new_key] = new_value
        result
      }
    end
  end
end

unless String.method_defined?(:underscore)
  class String
    def underscore
      self.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end
  end
end
