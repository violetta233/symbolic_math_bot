# frozen_string_literal: true

module States
  class BaseState
    attr_reader :bot, :message, :store, :text, :chat_id, :uid

    def initialize(bot, message, store)
      @bot = bot
      @message = message
      @store = store
      @text = message.text
      @chat_id = message.chat.id
      @uid = message.from.id
    end

    def handle
      raise NotImplementedError
    end

    protected

    def send_msg(text, kb = nil)
      opt = { chat_id: @chat_id, text: text }
      opt[:reply_markup] = kb if kb
      @bot.api.send_message(opt)
    end

    def typing
      @bot.api.send_chat_action(chat_id: @chat_id, action: 'typing')
    end

    def main_kb
      {
        keyboard: [
          ['Дифференцировать', 'Интегрировать'],
          ['Решить уравнение', 'Раскрыть скобки'],
          ['История', 'Статистика'],
          ['Помощь', 'Отмена']
        ],
        resize_keyboard: true
      }
    end

    def cancel_kb
      { keyboard: [['Отмена']], resize_keyboard: true, one_time_keyboard: true }
    end

    def fmt(s)
      s.gsub(/\.0(?=[^0-9]|$)/, '')
    end
  end
end