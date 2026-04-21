require 'minitest/autorun'
require_relative '../bot'

class TestParticipant1 < Minitest::Test
  def setup
    @store = UserStore.new('test.json')
  end

  def teardown
    File.delete('test.json') if File.exist?('test.json')
  end

  def test_get_user
    u = @store.get(123)
    assert_equal 'main', u['state']
  end

  def test_set_state
    @store.set_state(123, 'wait_diff')
    assert_equal 'wait_diff', @store.state(123)
  end

  def test_add_history
    @store.add_history(123, 'diff', 'x^2', '2x')
    assert_equal 1, @store.history(123).size
  end

  def test_clear_history
    @store.add_history(123, 'diff', 'x', '1')
    @store.clear_history(123)
    assert_empty @store.history(123)
  end

  def test_stats
    @store.add_history(123, 'diff', 'x', '1')
    @store.add_history(123, 'integ', 'x', '1')
    s = @store.stats(123)
    assert_equal 2, s['total']
    assert_equal 1, s['diff']
    assert_equal 1, s['integ']
  end

  def test_last
    @store.add_history(123, 'diff', 'x^2', '2x')
    last = @store.last(123)
    assert_equal 'x^2', last['expr']
    assert_equal '2x', last['result']
  end

  def test_reset
    @store.set_state(123, 'wait_diff')
    @store.reset(123)
    assert_equal 'main', @store.state(123)
  end
end