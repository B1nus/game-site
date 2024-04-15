# frozen_string_literal: true

require 'sinatra'
require 'sinatra/flash'
require 'sinatra/reloader'
require_relative 'helpers'
require_relative 'model'
require_relative 'routes/games'
require_relative 'routes/tags'
require_relative 'routes/tag_purposes'
require_relative 'routes/users'

# Validering i model, inte app

# Used for login
enable :sessions

# Yardoc
# include Model

# Database
database = Model.new

on_start do
  puts 'Server started as http://localhost:4567'
end

on_stop do
  puts 'By Bye!'
end

# Needed to expose the database to my './helper.rb' file
before('*') do
  @database = database
end

# Protect admin and user sites
before('/admin/*') do
  admin_check
end

before('/user*') do
  user_check
end

# Användare crud, Kolla rätt user_id först
# Gillning av spel, kolla för inloggad, annars error, kolla även rätt user_id
# kanske abtrahera user_id check som med helpers::admin?
# /admin/games, edit å delete knapp
# flash för lyckad loggin? flash for om du inte är inloggad istället för redirect?

# Restful routes viktigt? Strunta i det för likes, men gör det för tags och spel
# Domän check i app.rb.
# Ta bort länken till scratch see inside. Gör så det är till servern istället
# Cooldown för inloggningsförsök. request.ip
#
# Regex validering på några fält. Även med tid för A nivå.
#
# before /admin/* . Gör så för alla admin routes
# gör en separat /admin/games/ index sida med edit och delete knappar
# login ip sparning
# login validering
# login autentisering i model.rb
