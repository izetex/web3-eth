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

    end
  end
end