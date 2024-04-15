# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require_relative 'model'
require_relative 'helpers'
require_relative 'control/routes'

# Validering i model, inte app

# Used for login
enable :sessions

# Yardoc
# include Model

# Database
database = Model.new

on_start { puts 'Server started as http://localhost:4567' }
on_stop { puts 'By Bye!' }

# Needed to expose the database to my './helper.rb' file
before('*') { @database = database }

# Protect admin and user sites
before('/admin/*') { admin_check }
before('/user*') { user_check }

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
