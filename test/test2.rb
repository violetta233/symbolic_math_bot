require 'minitest/autorun'
require 'symbolic_math'

class TestParticipant2 < Minitest::Test
  def test_diff_x3
    p = SymbolicMath::Parser.parse('x^3')
    assert_equal '3.0*x^2', p.differentiate.to_s
  end

  def test_diff_constant
    p = SymbolicMath::Parser.parse('5')
    assert_equal '0', p.differentiate.to_s
  end

  def test_diff_polynomial
    p = SymbolicMath::Parser.parse('2*x^3 + 4*x^2 + x + 5')
    assert_equal '6.0*x^2 + 8.0*x + 1.0', p.differentiate.to_s
  end

  def test_diff_negative
    p = SymbolicMath::Parser.parse('-3*x^2')
    assert_equal '-6.0*x', p.differentiate.to_s
  end


  def test_integrate_x2
    p = SymbolicMath::Parser.parse('x^2')
    assert_equal '0.3333333333333333*x^3', p.integrate.to_s
  end

  def test_integrate_constant
    p = SymbolicMath::Parser.parse('5')
    assert_equal '5.0*x', p.integrate.to_s
  end

  def test_integrate_polynomial
    p = SymbolicMath::Parser.parse('3*x^2 + 2*x + 1')
    assert_equal '1.0*x^3 + 1.0*x^2 + 1.0*x', p.integrate.to_s
  end
end