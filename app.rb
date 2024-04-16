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
# Gillning av spel, kolla för inloggad, annars error, kolla även rätt user_id
# Crud och RESTFUL är inte smidig alls. Prova något annat. Typ slim filer i views, någon enstaka
# Likes å lista av gillade spel i /user
# Ta bort länken till scratch see inside. Gör så det är till servern istället

# Used for login
enable :sessions

# Database
database = Model.new

# Print a link with the website address upon startup
#
on_start do
  puts 'Server started as http://localhost:4567'
end

# Exposes the database to other files, such as helpers.rb, or routes/*.rb
#
before('*') do
  @database = database
end

# Display a message and redirect if user doesn't have admin privileges
#
before('/admin/*') do
  unless admin?
    flash[:notice] = 'You do not have admin privileges'
    redirect '/'
  end
end

# Displays a message and redirects if user is not logged into it's account
#
before('/user*') do
  unless user?
    flash[:notice] = 'You need to login to do that'
    redirect '/'
  end
end
