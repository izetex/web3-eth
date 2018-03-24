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
end
