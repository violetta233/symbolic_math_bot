# frozen_string_literal: true

require_relative 'base_state'
require 'symbolic_math'

module States
  class WaitExpandState < BaseState
    def handle
      typing
      return send_msg('Пусто', cancel_kb) if @text.strip.empty?
      begin
        result = SymbolicMath::Expander.expand(@text)
        
        @store.add_history(@uid, 'expand', @text, fmt(result.to_s))
        @store.set_state(@uid, 'main')
        send_msg("Результат: #{fmt(result.to_s)}", main_kb)
      rescue => e
        send_msg("Ошибка: #{e.message}", cancel_kb)
      end
    end
  end
end
