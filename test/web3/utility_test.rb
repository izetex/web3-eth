require_relative '../test_helper'

describe Web3::Eth::Utility do
  before do
    @util = Object.new
    @util.send(:extend, Web3::Eth::Utility)
  end

  it '#hex' do
    assert_equal "0x3e8", @util.hex(1000)
  end

  it '#wei_to_ether' do
    assert_equal 12.34501, @util.wei_to_ether(12345010000000000000)
  end

  it '#ether_to_wei' do
    assert_equal 12345010000000000000, @util.ether_to_wei(12.34501)
  end

  it '#from_hex' do
    assert_equal 1000, @util.from_hex("0x3e8")
  end

  it '#remove_0x_head' do
    assert_equal "3e8", @util.remove_0x_head("0x3e8")
  end
end
