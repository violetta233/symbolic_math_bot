# frozen_string_literal: true

require 'telegram/bot'
require 'dotenv/load'
require 'symbolic_math' 
require 'json'

require_relative 'states/base_state'
require_relative 'states/main_state'
require_relative 'states/wait_diff_state'
require_relative 'states/wait_integrate_state'
require_relative 'states/wait_solve_state'
require_relative 'states/wait_expand_state'

TOKEN = ENV['BOT_TOKEN']

#  ХРАНИЛИЩЕ 

class UserStore
  def initialize(file = 'users.json')
    @file = file
    @data = File.exist?(file) ? JSON.parse(File.read(file)) : {}
  end

  def save
    File.write(@file, JSON.pretty_generate(@data))
  end

  def get(uid)
  uid = uid.to_s
  if !@data[uid]
    @data[uid] = {
      'state' => 'main',
      'history' => [],
      'stats' => { 'total' => 0, 'diff' => 0, 'integ' => 0, 'solve' => 0, 'expand' => 0 },
      'last' => { 'expr' => '', 'result' => '' }
    }
    save
  end
  @data[uid]
end

  def state(uid)
    get(uid)['state']
  end

  def set_state(uid, s)
    get(uid)['state'] = s
    save
  end

  def add_history(uid, cmd, inp, out)
    h = get(uid)['history']
    h << { cmd: cmd, input: inp, output: out, time: Time.now.to_s }
    h.shift if h.size > 30
    stats = get(uid)['stats']
    stats['total'] += 1
    stats[cmd] += 1
    get(uid)['last'] = { expr: inp, result: out }
    save
  end

  def history(uid, limit = 15)
    get(uid)['history'].last(limit)
  end

  def clear_history(uid)
    get(uid)['history'] = []
    save
  end

  def stats(uid)
    get(uid)['stats']
  end

  def last(uid)
    get(uid)['last']
  end

  def reset(uid)
    uid.to_s
    save
  end
end

$store = UserStore.new

def main_keyboard
  {
    keyboard: [
      [{ text: 'Дифференцировать' }, { text: 'Интегрировать' }],
      [{ text: 'Решить уравнение' }, { text: 'Раскрыть скобки' }],
      [{ text: 'История' }, { text: 'Статистика' }],
      [{ text: 'Помощь' }, { text: 'Отмена' }]
    ],
    resize_keyboard: true
  }
end

def cancel_keyboard
  { keyboard: [['Отмена']], resize_keyboard: true, one_time_keyboard: true }
end

def send_msg(bot, chat_id, text, kb = nil)
  opt = { chat_id: chat_id, text: text }  # убрали , parse_mode: 'Markdown'
  opt[:reply_markup] = kb if kb
  bot.api.send_message(opt)
end

def typing(bot, chat_id)
  bot.api.send_chat_action(chat_id: chat_id, action: 'typing')
end

# ГЛАВНЫЙ ЦИКЛ БОТА 

puts 'Бот запущен'

begin
  Telegram::Bot::Client.run(TOKEN) do |bot|
    bot.listen do |message|
      next unless message.is_a?(Telegram::Bot::Types::Message)
      next unless message.text
      text = message.text
      chat_id = message.chat.id
      uid = message.from.id
      username = "#{message.from.username} (#{message.from.first_name})"

      puts "[#{uid}] #{username}: #{text}"

      cur_state = $store.state(uid)
      puts "DEBUG: Current state for #{uid}: #{cur_state}"
      handled = false

      #  БАЗОВЫЕ КОМАНДЫ

      if text == '/start'
        $store.reset(uid)
        welcome = <<~TEXT
          *Привет, #{username}!*
          Я бот для символьной математики.

          *Команды:*
          /diff [выражение] - производная
          /integrate [выражение] - интеграл
          /solve [уравнение] - решение
          /expand [выражение] - раскрыть скобки

          /history - история
          /stats - статистика
          /last - последний результат
          /clear - очистить историю
          /cancel - отмена
          /help - справка
        TEXT
        send_msg(bot, chat_id, welcome, main_keyboard)
        handled = true
        next
      end
      if text == '/help' || text == 'Помощь'
        help = <<~TEXT
          *Справка*
          *Математика:*
          `/diff 3*x^2` → `6*x`
          `/integrate x^2` → `x^3/3 + C`
          `/solve x^2-4=0` → `x₁ = 2, x₂ = -2`
          `/expand (x+2)*(x-3)` → `x^2 - x - 6`
          *Управление:*
          `/history` - показать историю
          `/stats` - статистика
          `/last` - последний результат
          `/clear` - очистить историю
          `/cancel` - отменить действие
          `/menu` - показать меню
        TEXT
        send_msg(bot, chat_id, help)
        handled = true
        next
      end

      if text == '/menu'
        send_msg(bot, chat_id, '*Главное меню*', main_keyboard)
        handled = true
        next
      end

      if text == '/cancel' || text == 'Отмена'
        $store.set_state(uid, 'main')
        send_msg(bot, chat_id, 'Действие отменено', main_keyboard)
        handled = true
        next
      end

      if text == '/history' || text == 'История'
        hist = $store.history(uid)
        if hist.empty?
          send_msg(bot, chat_id, 'История пуста')
        else
          msg = "*История операций*\n\n"
          hist.each_with_index do |h, i|
            msg += "#{i+1}. *#{h['cmd'].capitalize}*\n"
            msg += "   `#{h['input'][0..40]}`\n"
            msg += "   → `#{h['output'][0..40]}`\n\n"
          end
          send_msg(bot, chat_id, msg)
        end
        handled = true
        next
      end

      if text == '/stats' || text == 'Статистика'
        s = $store.stats(uid)
        msg = <<~TEXT
          *Ваша статистика*

          Всего операций: *#{s['total']}*

          Дифференцирований: #{s['diff']}
          Интегрирований: #{s['integ']}
          Решений уравнений: #{s['solve']}
          Раскрытий скобок: #{s['expand']}
        TEXT
        send_msg(bot, chat_id, msg)
        handled = true
        next
      end

      if text == '/last'
        last = $store.last(uid)
        if last['expr'].empty?
          send_msg(bot, chat_id, 'Нет сохранённых результатов')
        else
          send_msg(bot, chat_id, "*Последний результат*\n\n`#{last['expr']}\n\n`#{last['result']}")
        end
        handled = true
        next
      end

      if text == '/clear'
        $store.clear_history(uid)
        send_msg(bot, chat_id, 'История очищена')
        handled = true
        next
      end

            # КНОПКИ МЕНЮ 
      if text == '/diff'
        $store.set_state(uid, 'wait_diff')
        send_msg(bot, chat_id, 'Введите выражение для дифференцирования\n\nПример: 3*x^2 + 2*x + 1', cancel_keyboard)
        handled = true
        next
      end

      if text == '/integrate'
        $store.set_state(uid, 'wait_integrate')
        send_msg(bot, chat_id, 'Введите выражение для интегрирования\n\nПример: x^2 + 3*x', cancel_keyboard)
        handled = true
        next
      end

      if text == '/solve'
        $store.set_state(uid, 'wait_solve')
        send_msg(bot, chat_id, 'Введите уравнение\n\nПримеры:\n`2*x + 3 = 7`\n`x^2 - 5*x + 6 = 0`', cancel_keyboard)
        handled = true
        next
      end

      if text == '/expand'
        $store.set_state(uid, 'wait_expand')
        send_msg(bot, chat_id, 'Введите выражение со скобками\n\nПример: (x+2)*(x-3)', cancel_keyboard)
        handled = true
        next
      end

      # ОБРАБОТКА СОСТОЯНИЙ (только если ничего не обработали)
      unless handled
        state_class = case cur_state
        when 'main'
          States::MainState
        when 'wait_diff'
          States::WaitDiffState
        when 'wait_integrate'
          States::WaitIntegrateState
        when 'wait_solve'
          States::WaitSolveState
        when 'wait_expand'
          States::WaitExpandState
        else
          States::MainState
        end

        state = state_class.new(bot, message, $store)
        state.handle
      end
    end
  end
rescue => e
  puts "Критическая ошибка: #{e.message}"
  puts e.backtrace
end