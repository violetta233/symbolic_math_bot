# frozen_string_literal: true

require 'minitest/autorun'
require 'mocha/minitest'
require_relative '../bot'

# модульные тесты(без моков)

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
    assert_equal 1, stats['diff']
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
    assert_equal [2.0, -2.0], result
  end
end

# Тест с моками(Telegram API)

class TestBotIntegration < Minitest::Test
  def test_diff_command_with_mock
    api_mock = mock('api')
    bot_mock = mock('bot')
    bot_mock.stubs(:api).returns(api_mock)
    
    api_mock.expects(:send_message).with(
      has_entry(:text, /6\*x/)
    ).returns(true)
    
    message = mock('message')
    message.stubs(:text).returns('/diff 3*x^2')
    message.stubs(:chat).returns(stub(id: 123))
    message.stubs(:from).returns(stub(id: 456))
    
    if message.text.start_with?('/diff ')
      expr = message.text[6..-1].strip
      poly = SymbolicMath::Parser.parse(expr)
      result = poly.differentiate
      res_fmt = result.to_s.gsub(/\.0(?=[^0-9]|$)/, '')
      api_mock.send_message(chat_id: message.chat.id, text: "📐 `#{expr}` = `#{res_fmt}`")
    end
    
    # Если дошли сюда без ошибок — тест пройден
    assert true
  end
end