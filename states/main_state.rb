# frozen_string_literal: true

require_relative 'base_state'

module States
  class MainState < BaseState
    def handle
      case @text
      when '/start'
        @store.reset(@uid)
        send_msg("Привет!\n\nКоманды: /diff, /integrate, /solve, /expand\n/history, /stats, /last, /clear, /cancel, /help", main_kb)
      when '/help', 'Помощь'
        send_msg("/diff 3*x^2 → 6*x\n/integrate x^2 → x^3/3 + C\n/solve x^2-4=0 → x₁=2, x₂=-2\n/expand (x+2)*(x-3) → x^2-x-6")
      when '/menu'
        send_msg('Меню', main_kb)
      when '/cancel', 'Отмена'
        @store.set_state(@uid, 'main')
        send_msg('Отменено', main_kb)
      when '/history', 'История'
        hist = @store.history(@uid)
        if hist.empty?
          send_msg('История пуста')
        else
          msg = "История:\n"
          hist.each_with_index { |h, i| msg += "#{i+1}. #{h['cmd']}: #{h['input']} = #{h['output']}\n" }
          send_msg(msg)
        end
      when '/stats', 'Статистика'
        s = @store.stats(@uid)
        send_msg("Операций: #{s['total']}\nДифф: #{s['diff']}\nИнтег: #{s['integ']}\nРешений: #{s['solve']}\nРаскрытий: #{s['expand']}")
      when '/last'
        last = @store.last(@uid)
        last['expr'].empty? ? send_msg('Нет результатов') : send_msg("Последнее: #{last['expr']} = #{last['result']}")
      when '/clear', '🗑 Очистить'
        @store.clear_history(@uid)
        send_msg('История очищена')
      when 'Дифференцировать'
        @store.set_state(@uid, 'wait_diff')
        send_msg('Введите выражение', cancel_kb)
      when 'Интегрировать'
        @store.set_state(@uid, 'wait_integrate')
        send_msg('Введите выражение', cancel_kb)
      when 'Решить уравнение'
        @store.set_state(@uid, 'wait_solve')
        send_msg('Введите уравнение', cancel_kb)
      when 'Раскрыть скобки'
        @store.set_state(@uid, 'wait_expand')
        send_msg('Введите выражение', cancel_kb)
      else
        send_msg('Неизвестно. /help', main_kb) if @store.state(@uid) == 'main'
      end
    end
  end
end