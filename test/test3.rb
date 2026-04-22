require 'minitest/autorun'
require 'symbolic_math'

class TestParticipant3 < Minitest::Test
  def test_solve_linear
    r = SymbolicMath::Solver.solve('2*x+3=7', 'x')
    assert_equal [2.0], r
  end

  def test_solve_quadratic_two
    r = SymbolicMath::Solver.solve('x^2-5*x+6=0', 'x')
    assert_equal [2.0, 3.0], r
  end

  def test_solve_quadratic_one
    r = SymbolicMath::Solver.solve('x^2-4*x+4=0', 'x')
    assert_equal [2.0], r
  end

  def test_solve_quadratic_none
    r = SymbolicMath::Solver.solve('x^2+x+1=0', 'x')
    assert_equal :no_real_roots, r
  end

  def test_solve_no_solution
    r = SymbolicMath::Solver.solve('0*x+5=0', 'x')
    assert_equal :no_solution, r
  end

  def test_solve_infinite
    r = SymbolicMath::Solver.solve('0*x=0', 'x')
    assert_equal :infinite_solutions, r
  end

  def test_expand_simple
    poly = SymbolicMath::Parser.parse('(x+2)*(x-3)')
    result = poly.to_s
    assert result.is_a?(String)
    assert !result.empty?
  end
end
