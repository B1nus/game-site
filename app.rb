require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require "./helper_functions"

# Återkoppla användaren till browse sidan som fungerar som index sida
get('/') do
    redirect('/browse')
end

# Visa sidan där man kan söka efter spel
get('/browse') do
    db = connect_to_default_database()
    
    slim(:browse)
end

# Restful routes viktigt? (blir simplare utan dem i mitt fall)
# Domänbeskrivning var?
# Yardoc?