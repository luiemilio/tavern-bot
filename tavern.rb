require 'byebug'
require 'telegram/bot'
require 'excon'
require 'rubygems'
require 'json'
require_relative 'token'
require 'byebug'

def convert_search_term(search_term)
  search_term.split("").map do |chr|
    chr == " " ? '%20' : chr
  end.join
end

def has_digits?(str)
  str.count("0-9") > 0
end

def get_cards(search_term)
  converted_search_term = convert_search_term(search_term)
  mashape_token = Tokens::TOKENS['mashape']
  response = Excon.get("https://omgvamp-hearthstone-v1.p.mashape.com/cards/search/#{converted_search_term}?collectible=1",
                        headers: { 'X-Mashape-Key' => mashape_token, 'collectible' => 1 })
  body = JSON.parse(response.body)
  body.class == Hash ? [] : body
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
      query = message.query
      if !query.nil? && query.length > 3 && !has_digits?(query)
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
