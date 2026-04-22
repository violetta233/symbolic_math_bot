# frozen_string_literal: true

require_relative 'base_state'

module States
  class MainState < BaseState
    def handle
      if @store.state(@uid) == 'main'
        send_msg('Используйте кнопки или /help', main_kb)
      end
    end
  end
end