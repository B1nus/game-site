require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'

# Återkoppla användaren till browse sidan som fungerar som index sida
get('/') do
    redirect('/browse')
end

# Visa sidan där man kan söka efter spel
get('/browse') do
    slim(:browse)
end

# Restful routes viktigt? (blir simplare utan dem i mitt fall)
# Domänbeskrivning var?
# Yardoc?