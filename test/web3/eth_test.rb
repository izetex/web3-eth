require_relative '../test_helper'

describe Web3::Eth, vcr: { record: :new_episodes } do
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
    assert_equal 2897548, number
  end

  describe '#getTransactionByHash' do
    it 'returns object' do
      t = @web3.eth.getTransactionByHash('0x4f755679e282e73eb00787a517c932cc2830ea3992392e040a381dcd60da3a7c')
      assert_equal 2879509, t.block_number
      assert_equal "0x4f755679e282e73eb00787a517c932cc2830ea3992392e040a381dcd60da3a7c", t.hash
      assert_equal 1000000000000000000, t.value
      assert_equal 1.0, t.value_eth
    end

    it 'returns hash' do
      t = @web3.eth.getTransactionByHash('0x4f755679e282e73eb00787a517c932cc2830ea3992392e040a381dcd60da3a7c', false)
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
end
