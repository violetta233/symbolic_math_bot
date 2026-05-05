# frozen_string_literal: true

require_relative 'base_state'
require 'symbolic_math'

module States
  class WaitDiffState < BaseState
    def handle
      typing
      expr = @text.strip
      
      if expr.start_with?('/diff ')
        expr = expr[6..-1].strip
      end
      
      if expr.empty?
        send_msg("❌ Выражение не может быть пустым", cancel_kb)
        return
      end
      
      begin
        poly = SymbolicMath::Parser.parse(expr)
        res = poly.differentiate
        res_fmt = fmt(res.to_s)
        
        @store.add_history(@uid, 'diff', expr, res_fmt)
        @store.set_state(@uid, 'main')
        
        send_msg("📐 `#{expr}` = `#{res_fmt}`", main_kb)
      rescue => e
        send_msg("❌ Ошибка: #{e.message}", cancel_kb)
      end
    end
  end
end