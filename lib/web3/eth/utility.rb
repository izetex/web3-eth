module Web3
  module Eth

    module Utility

      def hex num
        '0x' + num.to_s(16)
      end

      def wei_to_ether(wei)
        1.0 * wei / 10**18
      end

      def from_hex h
        h.to_i 16
      end

      def remove_0x_head(s)
        s[0,2] == '0x' ? s[2..-1] : s
      end

      def symbolize_keys(hash)
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

      def to_snakecase(method_name)
        method_name.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
      end
    end
  end
end
