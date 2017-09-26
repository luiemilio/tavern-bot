require 'byebug'
require 'telegram/bot'
require 'excon'
require 'rubygems'
require 'json'
require_relative 'token'


def get_cards(search_term)
  mashape_token = Tokens::TOKENS['mashape']
  response = Excon.get("https://omgvamp-hearthstone-v1.p.mashape.com/cards/search/#{search_term}?collectible=1",
                        headers: { 'X-Mashape-Key' => mashape_token, 'collectible' => 1 })
  JSON.parse(response.body)
end


def create_photo_instance(card)
  Telegram::Bot::Types::InlineQueryResultPhoto.new(
    id: card['cardId'],
    photo_url: card['img'],
    thumb_url: card['img']
  )
end

Telegram::Bot::Client.run(Tokens::TOKENS['telegram']) do |bot|
  bot.listen do |message|
    case message
    when Telegram::Bot::Types::InlineQuery
      if !message.query.nil? && message.query.length > 3
        cards = get_cards(message.query)
        mapped_cards = cards.map { |card| create_photo_instance(card) }
        bot.api.answer_inline_query(
          inline_query_id: message.id,
          results: mapped_cards
        )
      end
    end
  end
end
