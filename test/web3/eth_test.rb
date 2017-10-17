require 'test_helper'

class Web3::EthTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Web3::Eth::VERSION
  end

  def test_it_does_something_useful
    assert false
  end
end
