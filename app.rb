require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require "./helper_functions"

p "http://localhost:4567/"

# Återkoppla användaren till browse sidan som fungerar som index sida
get('/') do
    redirect('/games')
end

# Visa sidan där man kan söka efter spel
get('/games') do
    db = connect_to_default_database()

    games = db.execute("SELECT * FROM game")

    slim(:"games/index", locals:{games:games})
end

# Spela ett spel
get('/games/:id') do
    db = connect_to_default_database()

    game_id = params[:id]

    game = db.execute("SELECT * FROM game WHERE id = ?", game_id).first

    slim(:"games/show", locals:{game:game})
end

# 

# Restful routes viktigt? (blir simplare utan dem i mitt fall)
# Domänbeskrivning var?
# Yardoc?