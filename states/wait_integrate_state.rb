# frozen_string_literal: true

require_relative 'base_state'
require 'symbolic_math'

module States
  class WaitIntegrateState < BaseState
    def handle
      typing
      return send_msg('Пусто', cancel_kb) if @text.strip.empty?
      begin
        res = SymbolicMath::Parser.parse(@text).integrate
        @store.add_history(@uid, 'integ', @text, fmt(res.to_s))
        @store.set_state(@uid, 'main')
        send_msg("Интеграл: #{fmt(res.to_s)} + C", main_kb)
      rescue => e
        send_msg("Ошибка: #{e.message}", cancel_kb)
      end
    end
  end
end