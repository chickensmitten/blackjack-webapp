require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17
INITIAL_POT_AMOUNT = 500

helpers do #helpers are like modules
#map through each elements to map each of the ieams in the array and provide the total value.
  def calculate_total(cards)
    arr = cards.map{|element| element[1]}

    total = 0
    arr.each do |a|
      if a == "A"
        total += 11 #+= is to add the integers into total which is 0.
      else
        total += a.to_i == 0 ? 10 : a.to_i #when we call a to integer and the value is zero, it will then be 10. This is for J, Q, K. Otherwise, we will just take the integer value from a.to_i
      end
    end

    arr.select{|element| element == "A"}.count.times do
      break if total <= BLACKJACK_AMOUNT
      total -= 10
    end

    total #return the total value
  end

  def card_image(card) # ['H', '4']
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end

  "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>" # present the cards according to the suits and values defined. be minded of how the images are sourced and class call.
  end

  def winner!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    session[:player_pot] = session[:player_pot] + session[:player_bet] 
    @winner = "<strong>#{session[:player_name]} wins! </strong> #{msg}"
  end

  def loser!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    session[:player_pot] = session[:player_pot] - session[:player_bet]     
    @loser = "<strong>#{session[:player_name]} loses. </strong> #{msg}"    
  end

  def tie!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @winner = "<strong> It's a tie! </strong> #{msg}"
  end

end


before do # this is to say, before every single action. same as copying this instance variable and put it into each of the methods.
  @show_hit_or_stay_buttons = true
end


get '/' do #each of these methods are encapsulated within the "get" and "post" method with routes correlating to requests.
  if session[:player_name]
    redirect '/game'
  else
    redirect '/set_name'
  end
end

get '/bet' do
  session[:player_bet] = nil
  erb :bet
end

post '/bet' do
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "Must make a bet."
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:player_pot]
    @error = "Bet amount cannot be greater than what you have. ($#{session[:player_pot]})"
    halt erb(:bet)
  else #happy path
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end

  session[:bet_amount] = params[:bet_amount]
  redirect '/game'
end

get '/set_name' do
  session[:player_pot] = INITIAL_POT_AMOUNT
  erb :set_name
end

post '/set_name' do
  if params[:player_name].empty?
    @error = "name is required"
    halt erb(:set_name)
  end

  session[:player_name] = params[:player_name]
  #progress to the game
  redirect '/bet'
end

get '/game' do
  session[:turn] = session[:player_name]
  # deck
  suits = ['H', 'D', 'C', 'S']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(values).shuffle! #product of suits array with values array 
  #deal cards

  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  #dealer cards
  #player cards
  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  
  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hit blackjack.")
  elsif calculate_total(session[:player_cards]) > BLACKJACK_AMOUNT
    # instance variables are not persistence that is why their use case is perfect for error message as the error condition may have gone away in the future. 
    # This references from @error message from layout.
    loser!("It looks like #{session[:player_name]} busted at #{player_total}.")
  end

  erb :game, layout: false #(1) dont want this part to return the gmae layout. (2) instead of using redirect method, which will restart the game, after pop, we just go back to game.
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} have chosen to stay."
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"
  @show_hit_or_stay_buttons = false
  dealer_total = calculate_total(session[:dealer_cards]) 

  if dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer hit Blackjack.")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealer_total}.")
  elsif dealer_total >= DEALER_MIN_HIT
    redirect '/game/compare'
  else
    @show_dealer_hit_button = true
  end

  erb :game, layout: false 
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  else
    tie!("Both #{session[:player_name]} and the dealer stayed at #{player_total}.")
  end

  erb :game, layout: false
end

get '/game_over' do
  erb :game_over
end






