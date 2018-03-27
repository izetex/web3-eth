$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'web3/eth'

require 'minitest/autorun'
require "minispec-metadata"
require "vcr"
require "minitest-vcr"
require "webmock"
require "mocha/setup"
require "faraday"
require "pry"

VCR.configure do |c|
  c.cassette_library_dir = 'test/cassettes'
  c.hook_into :webmock
end

MinitestVcr::Spec.configure!
