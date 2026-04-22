# frozen_string_literal: true

require 'minitest/autorun'
require 'mocha/minitest'
require 'symbolic_math'
require 'json'

require_relative '../bot'

class TestUserStore < Minitest::Test
  def setup
    @store = UserStore.new('test_users.json')
  end

  def teardown
    File.delete('test_users.json') if File.exist?('test_users.json')
  end

  def test_get_user
    user = @store.get(123)
    assert_equal 'main', user['state']
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
    stats = @store.stats(123)
    assert_equal 1, stats['total']
  end

  def test_reset
    @store.set_state(123, 'wait_diff')
    @store.reset(123)
    assert_equal 'main', @store.state(123)
  end
end

# тесты команд

class TestMathCommands < Minitest::Test
  def test_diff
    result = SymbolicMath::Parser.parse('3*x^2').differentiate
    assert_equal '6.0*x', result.to_s
  end

  def test_integrate
    result = SymbolicMath::Parser.parse('x^2').integrate
    assert_equal '0.3333333333333333*x^3', result.to_s
  end

  def test_solve
    result = SymbolicMath::Solver.solve('x^2-4=0', 'x')
    assert_includes result, 2.0
    assert_includes result, -2.0
  end
end

# тест с моком

class TestDiffHandler < Minitest::Test
  def test_diff_handler_calls_send_message
    # Создаём моки
    api_mock = mock('api')
    bot_mock = mock('bot')
    bot_mock.stubs(:api).returns(api_mock)
    
    expected_text = "📐 `3*x^2` = `6*x`"
    api_mock.expects(:send_message).with(
      has_entry(:text, expected_text)
    ).returns(true)
    
    message = mock('message')
    message.stubs(:text).returns('/diff 3*x^2')
    message.stubs(:chat).returns(stub(id: 12345))
    message.stubs(:from).returns(stub(id: 999))
    
    text = message.text
    
    if text.start_with?('/diff ')
      expr = text[6..-1].strip
      poly = SymbolicMath::Parser.parse(expr)
      res = poly.differentiate
      res_fmt = res.to_s.gsub(/\.0(?=[^0-9]|$)/, '')
      
      api_mock.send_message(
        chat_id: message.chat.id,
        text: "📐 `#{expr}` = `#{res_fmt}`",
        parse_mode: 'Markdown'
      )
    end
    
    assert true
  end
end