class Telegram::Messages::Start

  class << self

    def perform(_response)
      {
        header: '- Главное меню - ',
        buttons: [
          # Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Мои мероприятия', callback_data: 'my_invitations'),
          Telegram::Bot::Types::InlineKeyboardButton.new(
            {
              text: 'Мероприятия',
              callback_data: { processor: 'invitations' }.to_json
            }
          )
        ]
      }
    end

    def type
      :buttons
    end

  end
end