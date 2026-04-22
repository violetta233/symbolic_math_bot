# frozen_string_literal: true

require_relative 'base_state'
require 'symbolic_math'

module States
  class WaitDiffState < BaseState
    def handle
      typing
      return send_msg('Пусто', cancel_kb) if @text.strip.empty?
      begin
        expr = SymbolicMath::Parser.parse(@text)
        result = SymbolicMath::Differentiator.differentiate(expr, 'x')
        
        @store.add_history(@uid, 'diff', @text, fmt(result.to_s))
        @store.set_state(@uid, 'main')
        send_msg("Производная: #{fmt(result.to_s)}", main_kb)
      rescue => e
        send_msg("Ошибка: #{e.message}", cancel_kb)
      end
    end
  end
end 