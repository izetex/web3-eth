# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'web3/eth/version'

Gem::Specification.new do |spec|
  spec.name          = "web3-eth"
  spec.version       = Web3::Eth::VERSION
  spec.authors       = ["studnev"]
  spec.email         = ["aleksey@bloxy.info"]

  spec.summary       = %q{Web3 client to connect to Ethereum node by RPC.}
  spec.description   = %q{Calling RPC methods of Ethereum node with Ruby.}
  spec.homepage      = "https://github.com/Bloxy-info/web3-eth"
  spec.license       = "MIT"


  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency('rlp', '~> 0.7.3')
  spec.add_dependency('digest-sha3', '~> 1.1.0')
  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
