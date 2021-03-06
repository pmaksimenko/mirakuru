class Telegram::Callbacks::RefuseInvitation < Telegram::Base::DataCallback

  private

  def perform_actions
    invitation.fire_events!(:refuse)
  end

  def header
    [
      'Отказ от приглашения принят.'
    ]
  end

  def buttons
    [
      Telegram::Bot::Types::InlineKeyboardButton.new(
        {
          text: 'Главное меню',
          callback_data: {processor: 'start' }.to_json
        }
      )
    ]
  end

end