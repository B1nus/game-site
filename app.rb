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
    db = connect_to_default_database()

    @games = db.execute("SELECT * FROM game") # Alla attribut från alla spel är publika!!!

    slim(:"games/index")
end

# Spela ett spel
get('/games/:game_id') do
    db = connect_to_default_database()

    game_id = params[:game_id]

    @game = db.execute("SELECT * FROM game WHERE id = ?", game_id).first # Alla attribut från alla spel är publika!!!

    slim(:"games/show")
end

get('/warning/:game_id') do
    db = connect_to_default_database()

    game_id = params[:game_id]

    @foreign_url = db.execute("SELECT * FROM game WHERE id = ?", game_id).first["foreign_url"]
    @indigenous_url = "/games/" + game_id.to_s

    slim(:"warning")
end

# Restful routes viktigt? (blir simplare utan dem i mitt fall)
# Domänbeskrivning var?
# Yardoc?
# Ta bort länken till scratch see inside. Gör så det är till servern istället