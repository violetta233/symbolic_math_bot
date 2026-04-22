# frozen_string_literal: true

require_relative 'base_state'
require 'symbolic_math'

module States
  class WaitSolveState < BaseState
    def handle
      typing
      return send_msg('Пусто', cancel_kb) if @text.strip.empty?
      begin
        res = SymbolicMath::Solver.solve(@text, 'x')
        out = case res
        when :no_solution then 'Нет решений'
        when :infinite_solutions then '∞ Бесконечно решений'
        when :no_real_roots then 'Нет корней'
        when Array then res.size == 1 ? "x = #{res[0]}" : "x₁ = #{res[0]}, x₂ = #{res[1]}"
        else res.to_s
        end
        @store.add_history(@uid, 'solve', @text, out)
        @store.set_state(@uid, 'main')
        send_msg(out, main_kb)
      rescue => e
        send_msg("Ошибка: #{e.message}", cancel_kb)
      end
    end
  end
end
