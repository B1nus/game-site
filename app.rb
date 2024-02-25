require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require "./model"

# Länk för att komma in på hemsidan snabbt (:
p "http://localhost:4567/"

# Återkoppla användaren till browse sidan som fungerar som index sida
get('/') do
    redirect('/games')
end

# Visa sidan där man kan söka efter spel
get('/games') do
    @games = get_games() # Alla attribut från alla spel är publika!!!

    slim(:"games/index")
end

# Spela ett spel
get('/games/:game_id') do
    @game = database_game_by_id(params[:game_id]) # Alla attribut från alla spel är publika!!!

    slim(:"games/show")
end

get('/warning/:game_id') do
    game = database_game_by_id(params[:game_id])

    @foreign_url = game["foreign_url"]
    @indigenous_url = "/games/" + game_id.to_s

    slim(:"warning")
end

# Restful routes viktigt? Strunta i det för likes, men gör det för tags och spel
# Domän check i app.rb.
# Ta bort länken till scratch see inside. Gör så det är till servern istället