require_relative '../test_helper'

describe Web3::Eth::EthModule, vcr: { record: :new_episodes } do
  before do
    @uri  = URI.parse('http://104.155.178.241:8545/')
    @web3 = Web3::Eth::Rpc.new host: @uri.host, port: @uri.port
    @account_with_ether = '0x7f93a3a5060a69dce4d2428d5213ea15c1e0811f'
  end

  describe '#getBalance' do
    it 'returns ether' do
      assert_equal 1, @web3.eth.getBalance(@account_with_ether)
    end
    it 'returns wei' do
      assert_equal 1000000000000000000, @web3.eth.getBalance(@account_with_ether, 'latest', false)
    end
  end

  describe '#getBlockByNumber' do
    it 'returns object' do
      b = @web3.eth.getBlockByNumber(2897234)
      assert_equal 4362465331080531677, b.nonce
      assert_equal "0x64ac4303b5c5f0120512d19b4a1bd276be932e2eba0ec76db054e75082a2a24b", b.block_hash
    end

    it 'returns hash' do
      b = @web3.eth.getBlockByNumber(2897234, true, false)
      assert_equal "0x3c8a971af4030edd", b[:nonce]
      assert_equal "0x64ac4303b5c5f0120512d19b4a1bd276be932e2eba0ec76db054e75082a2a24b", b[:hash]
    end
  end

  it '#blockNumber' do
    number = @web3.eth.blockNumber
    assert_equal 2897990, number
  end

  describe '#getTransaction' do
    it 'returns object' do
      t = @web3.eth.getTransaction('0x4f755679e282e73eb00787a517c932cc2830ea3992392e040a381dcd60da3a7c')
      assert_equal 2879509, t.block_number
      assert_equal "0x4f755679e282e73eb00787a517c932cc2830ea3992392e040a381dcd60da3a7c", t.hash
      assert_equal 1000000000000000000, t.value
      assert_equal 1.0, t.value_eth
    end

    it 'returns hash' do
      t = @web3.eth.getTransaction('0x4f755679e282e73eb00787a517c932cc2830ea3992392e040a381dcd60da3a7c', false)
      assert_equal "0x2bf015", t[:blockNumber]
      assert_equal "0xde0b6b3a7640000", t[:value]
    end
  end

  describe '#getTransactionReceipt' do
    it 'returns object' do
      r = @web3.eth.getTransactionReceipt('0x4f755679e282e73eb00787a517c932cc2830ea3992392e040a381dcd60da3a7c')
      assert_equal 2879509, r.block_number
      assert_equal 1076732, r.cumulative_gas_used
    end

    it 'returns hash' do
      r = @web3.eth.getTransactionReceipt('0x4f755679e282e73eb00787a517c932cc2830ea3992392e040a381dcd60da3a7c', false)
      assert_equal "0x2bf015", r[:blockNumber]
      assert_equal "0x106dfc", r[:cumulativeGasUsed]
    end
  end

  describe '#gasPrice' do
    it 'in Ether' do
      price = @web3.eth.gasPrice()
      assert_equal 0.000000001, price
    end

    it 'in Wei' do
      price = @web3.eth.gasPrice(false)
      assert_equal 1000000000, price
    end
  end

  it '#sendTransaction' do
    from = '0xa04e958880f9b1557694b6aa6274cd111f5183dc'
    to   = '0x3f61159ce5e39ac27f3541a3f1f7ebb390a77f17'
    @web3.personal.unlockAccount(from, 'payment')
    txid = @web3.eth.sendTransaction([{from: from, to: to, value: 0.5, gas: 21_000}])
    assert_equal '0xd7e6ef89fd9c7a57bc12fc9219d11dd1e25ce0a0440daea894889d991a68109b', txid
  end

  it '#accounts' do
    accounts = ["0xa04e958880f9b1557694b6aa6274cd111f5183dc", "0x3f61159ce5e39ac27f3541a3f1f7ebb390a77f17", "0x3c51f8fc120ade8295dda3bb40878322590dcd27", "0x77535eeb8206007caef7e86c12f96685d0ecf0c0", "0xdf5a859f9efb916eb2afacfc977d78e0db282bbd", "0xae6fc061e05aa3b468d569ae6f85517005cacb2f", "0x5f0dae2ce068f147518d2463d4bde64bb9c8b09c", "0xd42050c24da173e52dcb87a2a414af5421ef3d68", "0x7f93a3a5060a69dce4d2428d5213ea15c1e0811f", "0x266ef67cec2f567faab06a163af664944ef9a8bf", "0x583cd9b0f50b0e8b3f1ced668f91d66b4f602b2b", "0xc2c9ed250c18ade71b34303c28676e7283b8bc79", "0xc42b00a6be5964b745e6d67933dcd8a92f3e38b0", "0xb88e69486b3be338c0472adf62399221efaf4bc2", "0xe14a93ac02c5fe511a2a1c320428f68c912aa6a3", "0x1f0159ba31a784dc8a999724ec26d8313ca87d3e", "0xf0d02680f7a6ccdff585f5b4af9067e5de9ade38", "0x6e037a6d38f09fbc34d6cc7f469f3e8f25f5afd1", "0x79a4d1c1064e84296f2df10112edcd1c04ac3269", "0x243afb7bca93b080013d8d8fd9c306a3518dee66"]
    assert_equal accounts, @web3.eth.accounts
  end
end
