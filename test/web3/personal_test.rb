require_relative '../test_helper'

describe Web3::Eth::PersonalModule, vcr: { record: :new_episodes } do
  before do
    @uri  = URI.parse('http://104.155.178.241:8545/')
    @web3 = Web3::Eth::Rpc.new host: @uri.host, port: @uri.port
  end

  it 'creates account and unlock' do
    account = @web3.personal.newAccount('helloworld')
    assert_equal '0x243afb7bca93b080013d8d8fd9c306a3518dee66', account
    resp = @web3.personal.unlockAccount(account, 'helloworld')
    assert_equal true, resp
  end
end
