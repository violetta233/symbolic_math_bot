# frozen_string_literal: true

require_relative 'base_state'
require 'symbolic_math'

module States
  class WaitSolveState < BaseState
    def handle
      typing
      return send_msg('Пусто', cancel_kb) if @text.strip.empty?
      begin
        result = SymbolicMath::Solver.solve(@text, 'x')
        result_str = result.is_a?(Array) ? result.join(', ') : result.to_s
        
        @store.add_history(@uid, 'solve', @text, result_str)
        @store.set_state(@uid, 'main')
        send_msg("Решение: #{result_str}", main_kb)
      rescue => e
        send_msg("Ошибка: #{e.message}", cancel_kb)
      end
    end
  end
end