require_relative '../test_helper'

describe Web3::Eth::PersonalModule, vcr: { record: :new_episodes } do
  before do
    @uri  = URI.parse('http://localhost:7545/')
    @web3 = Web3::Eth::Rpc.new host: @uri.host, port: @uri.port
  end

  it 'creates account and unlock' do
    account = @web3.personal.newAccount('helloworld')
    assert_equal '0xf0edab4b6ce0dce5ea5b750e4af77a92249d5fa6', account
    resp = @web3.personal.unlockAccount(account, 'helloworld')
    assert_equal true, resp
  end

  it '#sendTransaction' do
    from = '0xD6ae577521b30C0e6FC0F7Cb0ef30F4e75F059E5'
    to   = '0xD32C24Cf81d182A52984f9a0FfF68359b915fB60'
    txid = @web3.personal.sendTransaction({from: from, to: to, value: 0.1, gas: 21_000}, 'payment')
    assert_equal '0xd977bb5c074afec552bb6b06449283eb00f333bf4deb1e121aa4b1103a6a6c10', txid
  end
end
