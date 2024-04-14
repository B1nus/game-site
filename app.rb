# frozen_string_literal: true

require './model'
require './helpers'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'

# Used for login
enable :sessions

# Yardoc
# include Model

# Database
@database = Model.new

on_start; puts 'Server started as http://localhost:4567'
on_stop; puts 'By Bye!'

# Protect admin and user sites
before('/admin/*') { admin_check }
before('/user*') { user_check }

# One liner get routes.

# guest
get('/') { redirect '/games' }
get('/games') { erb :'games/index' }
get('/games/:id') { erb :'games/show' }
get('/register') { erb :'users/register' }
get('/login') { erb :'users/login' }
# user
get('/user') { erb :'users/edit' }
# admin
get('/admin/games') { erb :'games/index-admin' }
get('/admin/games/new') { erb :'games/new' }
get('/admin/games/:id/edit') { erb :'games/edit' }
get('/admin/tags/new') { erb :'tags/new' }
get('/admin/tags/:id/edit') { erb :'tags/edit', locals: { tag: tag(params[:id].to_i) } }
get('/admin/tags/:id') { erb :'tags/show' }
get('/admin/tags') { erb :'tags/index' }
get('/admin/users') { erb :'users/index' }

# Updates an existing game and redirects to '/admin/games'
post '/admin/games/:id/update' do
  # game_id = params[:id]
  #
  # tags_selection = params[:tags_selection]

  redirect '/admin/games'
end

# Add a new tag
#
# @param tag_name [String]
# @param tag_purpose_id [Integer]
post('/admin/tags') do
  @database.add_tag(params[:name], params[:purpose_id].to_i)
  redirect '/admin/tags'
end

# Update a tag
#
# @param [Integer] id, the id of the tag
# @param [String] tag_name, the new name of the tag
# @param [Integer] tag_purpose_id, the new tag purpose id
#
# @see Model#database_edit_tag
post('/admin/tags/:id/update') do
  @database.update_tag(params[:id], params[:name], params[:purpose_id])
  redirect '/admin/tags'
end

# Remove a tag
#
# @param [Integer] id, The id for the tag
post('/admin/tags/:id/delete') do
  @database.delete_tag(params[:id].to_i)
  redirect '/admin/tags'
end

# Create a new tag purpose
#
post('/admin/tag-purposes') do
  @database.add_tag_purpose(params[:purpose])
  redirect '/admin/tags'
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

  if error = @database.register_user(params[:username], params[:password], params[:repeat_password])
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

  if id = @database.login(params[:username], params[:password])
    # Successful login!
    change_user_id(id)
    redirect '/'
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

  redirect '/'
end

# Attempt to change a users username
#
# @params [String] username, the username
#
# @see Model#change_username
post '/user/username/edit' do
  cooldown_check '/user'

  flash[:notice] = @database.change_username(user_id, params[:username]).instance_eval do |e|
    e ? 'Username successfully changed!' : 'Username already taken'
  end

  redirect '/user'
end

# Attempt to change your password
#
# @params [String] password, your new password
# @params [String] repeat_password, same password another time to make sure you remember it
#
# @see Model#change_password
post '/user/password/edit' do
  cooldown_check '/user'

  error = @database.change_password(
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
  flash[:notice] = 'User successfully deleted'

  redirect '/'
end

# Delete a user
#
# @see Model#delete_user
post '/admin/users/:id/delete' do
  @database.delete_user(params[:id].to_i)
  flash[:notice] = 'User successfully deleted'

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
