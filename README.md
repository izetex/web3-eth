# Web3 RPC client for Ethereum node

This Ruby Gem is used to connect and communicate with Ethereum node ( geth, parity, etc),
having RPC interface. Also it has support to call Etherscan API.

What you can do using this GEM:

  - use Web3 eth interface methods to read blocks, transactions 
  - query Etherscan to get ABI for validated contracts
  - parse transaction method calls according to ABI
  - parse transaction logs according to ABI
  - parse contract creation arguments accroding to ABI
  - list internal transaction using parity extended trace JSONRPC API


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'web3-eth'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install web3-eth

## Usage

### Connect

Connecting to local node ( or by SSH Tunnel )

```ruby
web3 = Web3::Eth::Rpc.new
```

To connect to remote Ethereum node, follow instructions: https://github.com/paritytech/parity/wiki/Wallet-Remote-Access

If you need to connect to remote host, you can specify host, port and HTTP connection options:

```ruby
web3 = Web3::Eth::Rpc.new host: 'node.host.com', 
                          port: 8545,  
                          connect_options: { use_ssl: true, read_timeout: 120 } 
```

HTTP connection options are from  [Ruby HTTP](https://ruby-doc.org/stdlib-2.4.2/libdoc/net/http/rdoc/Net/HTTP.html)  plus additional optional property
**rpc_path** - path to RPC interface.

For example, to connect to infura node, you need the following configuration:

```ruby
web3 = Web3::Eth::Rpc.new host: 'mainnet.infura.io', 
                          port: 443,  
                          connect_options: {
                            open_timeout: 20,
                            read_timeout: 140,
                            use_ssl: true,
                            rpc_path: '/<YOUR INFURA PERSONAL KEY>'
                          }
```

or to connect to Ropsten:


```ruby
web3 = Web3::Eth::Rpc.new host: 'ropsten.infura.io', 
                          port: 443,  
                          connect_options: {
                            open_timeout: 20,
                            read_timeout: 140,
                            use_ssl: true
                          }
```

### Calling eth interface

```
>> web3.eth.blockNumber
4376369

>> web3.eth.getBalance '0x829BD824B016326A401d083B33D092293333A830'
3916.6597314456685

>> block = web3.eth.getBlockByNumber 4376369
#<Web3::Eth::Block:0x007f844d6f1138 @block_data={"author"=>"0x829bd824b016326a401d083b33d092293333a830", ...

>> block.timestamp_time
2017-10-17 12:51:36 +0300

>> block.transactions.count
129

>> block.transactions[0].from
"0xb2930b35844a230f00e51431acae96fe543a0347"

>> block.transactions[0].value_eth
0.51896811

```


### Calling Etherscan API:

```
api = Web3::Eth::Etherscan.new 'Your API Key'
abi = api.contract_getabi address: '0xe3fedaecd47aa8eab6b23227b0ee56f092c967a9'
```

Method name for Etherscan must be constructed as <module>_<action>, for example contract_getabi 
calls method getabi in module contract

If method accepts only one parameter address, the call can be simplified to:

```
abi = api.contract_getabi '0xe3fedaecd47aa8eab6b23227b0ee56f092c967a9'
```

### Accesing contract methods

```
# creation of contract object
myContract = web3.eth.contract(abi);

# initiate contract for an address
myContractInstance = myContract.at('0x2ad180cbaffbc97237f572148fc1b283b68d8861');

# call constant function
result = myContractInstance.balanceOf('0x...'); # any constant method works
puts result 
```

or using Etherscan API ( requires contract ABI be published in Etherescan ):

```
api = Web3::Eth::Etherscan.new 'Your API Key'
myContractInstance = web3.eth.load_contract(api, '0x2ad180cbaffbc97237f572148fc1b283b68d8861')

// call constant function
result = myContractInstance.balanceOf('0x....'); # any constant method works
puts result // '0x25434534534'
```


### Parsing transaction call arguments

Method parse_call_args parses call arguments according to ABI.
Code example is:

```
api = Web3::Eth::Etherscan.new 'Your API Key'
abi = api.contract_getabi address: '0x2ad180cbaffbc97237f572148fc1b283b68d8861'

myContract = web3.eth.contract(abi);
tx = web3.eth.getTransactionByHash '0x83da408b05061a2512fe1abf065b37a6aad9ae96d604b288a3da34bf9f1af9e6'
myContract.parse_call_args tx
```

### Parsing smart contract constructor arguments

Method parse_constructor_args parses smart contract creation arguments according to ABI.
Code example is:

```
api = Web3::Eth::Etherscan.new 'Your API Key'
abi = api.contract_getabi address: '0xf4702b0918a8a89dfc38459ce42198834818f26b'

myContract = web3.eth.contract(abi);
tx = web3.eth.getTransactionByHash '0x35f0cf1d1c7ec14dd40fe3949d1c535ec3f3953f118cb9dc1394370f966cf957'
myContract.parse_constructor_args tx
```

### Parsing transaction logs

Method parse_log_args parses indexed and not-indexed log event arguments according to ABI.
Code example is:

```
api = Web3::Eth::Etherscan.new 'Your API Key'
abi = api.contract_getabi address: '0x2ad180cbaffbc97237f572148fc1b283b68d8861'

myContract = web3.eth.contract(abi);
tx_receipt = web3.eth.getTransactionReceipt '0x83da408b05061a2512fe1abf065b37a6aad9ae96d604b288a3da34bf9f1af9e6'
myContract.parse_log_args tx_receipt.logs.first
```

### Listing internal transactions

To use this feature, you should run parity node with the option 
--tracing on, refer to [https://github.com/paritytech/parity/wiki/Configuring-Parity#cli-options].

```
calls = web3.trace.internalCallsByHash '0x7ac18a1640e443cd069ff51da382b92b585e42dae8f38db0932380bfe86908a6'
puts calls.first.from
puts calls.first.to
puts calls.first.value_eth
```



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Bloxy-info/web3-eth. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

