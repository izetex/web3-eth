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
        h.nil? ? 0 : (h.kind_of?(String) ? h.to_i(16) : h)
      end

      def remove_0x_head(s)
        return s if !s || s.length<2
        s[0,2] == '0x' ? s[2..-1] : s
      end

    end
  end
end