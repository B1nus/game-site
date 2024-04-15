# frozen_string_literal: true

require './model'
require './helpers'
require 'sinatra'
require_relative './controller/get_routes'
require 'sinatra/reloader'
require 'sinatra/flash'

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

get('/') do 'hello' end

# Protect admin and user sites
before('/admin/*') { admin_check }
before('/user*') { user_check }

# Updates an existing game and redirects to '/admin/games'
post '/admin/games/:id/update' do
  # name = params[:name]
  # tag_ids = params[:tags]
  # fullscreen = !params[:fullscreen].nil?
  # warning = !params[:warning].nil?
  # time_created = ???

  redirect '/games'
end

# Add a new tag
#
# @param tag_name [String]
# @param tag_purpose_id [Integer]
post('/admin/tags') do
  if params[:name].empty?
    flash[:notice] = 'The tag name can\'t be empty'
    redirect '/games'
  end

  database.add_tag(params[:name], params[:purpose_id].to_i)
  redirect '/games'
end

# Update a tag
#
# @param [Integer] id, the id of the tag
# @param [String] tag_name, the new name of the tag
# @param [Integer] tag_purpose_id, the new tag purpose id
#
# @see Model#database_edit_tag
post('/admin/tags/:id/update') do
  if params[:name].empty?
    flash[:notice] = 'The new tag name can\'t be empty'
    redirect '/games'
  end

  database.update_tag(params_id, params[:name], params[:purpose_id])
  redirect '/games'
end

# Remove a tag
#
# @param [Integer] id, The id for the tag
post('/admin/tags/:id/delete') do
  database.delete_tag(params_id)
  redirect '/games'
end

# Create a new tag purpose
#
post('/admin/tag-purposes') do
  if params[:purpose].empty?
    flash[:notice] = 'The tag purpose name can\'t be empty'
    redirect '/games'
  end

  database.add_tag_purpose(params[:purpose])
  redirect '/games'
end

# Attempts to register a user
#
# @param [String] username, The username
# @param [String] password, The password
# @param [String] repeat-password, The repeated password
#
# @see Model#register_user
post '/register' do
  cooldown_check '/register'

  if error = database.register_user(params[:username], params[:password], params[:repeat_password])
    flash[:notice] = error
    redirect '/register'
  else
    flash[:notice] = 'Registration successful!'
    redirect '/login'
  end
end

# Attempts to login
#
# @params [String] username, The username
# @params [String] password, The password
#
# @see Model#login
post '/login' do
  cooldown_check '/login'

  if id = database.login(params[:username], params[:password])
    # Successful login!
    change_user_id(id)
    redirect '/games'
  else
    # Login failed.
    flash[:notice] = 'Invalid login credentials'
    redirect '/login'
  end
end

# Logout a user and redirect to homepage
#
post '/logout' do
  logout

  redirect '/games'
end

# Attempt to change a users username
#
# @params [String] username, the username
#
# @see Model#change_username
post '/user/username/update' do
  cooldown_check '/user'

  flash[:notice] = database.change_username(user_id, params[:username]) || 'Username successfully changed!'

  redirect '/user'
end

# Attempt to change your password
#
# @params [String] password, your new password
# @params [String] repeat_password, same password another time to make sure you remember it
#
# @see Model#change_password
post '/user/password/update' do
  cooldown_check '/user'

  error = database.change_password(
    user_id,
    params[:current_password],
    params[:password],
    params[:repeat_password]
  )

  flash[:notice] = error || 'Password successfully changed!'

  redirect '/user'
end

# Delete the current user
#
# @see Model#delete_user
post '/user/delete' do
  delete_user user_id
  logout

  redirect '/games'
end

# Delete a user
#
# @see Model#delete_user
post '/admin/users/:id/delete' do
  delete_user params_id

  redirect '/admin/users'
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
