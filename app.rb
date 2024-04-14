# frozen_string_literal: true

require './model'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'

# Tillåt sessions. Jag använder det endast för inloggning
enable :sessions

# Yardoc
include Model

# Cooldown hash
$requests = {}
COOLDOWN_COUNT_LIMIT = 5 # Max number of requests
COOLDOWN_COUND_RESET_TIME = 5 # Time when the count is reset

helpers do
  def admin?; !session[:user_id].nil? && session[:user_id].zero? && user_permission_level(session[:user_id]) == 'admin' end

  def logged_in?; !session[:user_id].nil? && user_id_exists?(session[:user_id]) && session[:user_id] != 0 end

  def admin_check
    return if admin?

    flash[:notice] = 'No admin for you'
    redirect '/'
  end

  def login_check
    return if logged_in?

    flash[:notice] = 'You need to login'
    redirect '/'
  end

  def cooldown?
    site = request.path_info
    ip = request.ip

    $requests[site] ||= { site => {} }
    $requests[site][ip] ||= { count: 0, time: 0 }
    $requests[site][ip][:count] += 1

    $requests[site][ip][:count] = 0 if Time.now.to_i - $requests[site][ip][:time] >= COOLDOWN_COUND_RESET_TIME
    $requests[site][ip][:time] = Time.now.to_i

    $requests[site][ip][:count] >= COOLDOWN_COUNT_LIMIT
  end

  def cooldown_check redirect_url
    return unless cooldown?

    flash[:notice] = 'Calm down there, your making to many requests'
    redirect redirect_url
  end
end

# Meddelande vid start och stop av servern
on_start do puts "Server started as http://localhost:4567" end
on_stop do puts "By Bye!" end

# Validate protected sites, for admin and user
before '/admin/*' do admin_check end
before '/user*' do login_check end

# Guest sites
get '/' do redirect '/games' end
get '/games' do erb :'games/index' end
get '/games/:id' do erb :'games/show' end
get '/register' do erb :'users/register' end
get '/login' do erb :'users/login' end
# User site
get '/user' do erb :'users/edit' end
# Admin sites
get '/admin/games' do erb :'games/index-admin' end
get '/admin/games/new' do erb :'games/new' end
get '/admin/games/:id/edit' do erb :'games/edit' end
get '/admin/tags/new' do erb :'tags/new' end
get '/admin/tags/:id/edit' do erb :'tags/edit', locals:{tag:tag(params[:id].to_i)} end
get '/admin/tags/:id' do erb :'tags/show' end
get '/admin/tags' do erb :'tags/index' end
get '/admin/users' do erb :'users/index' end

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
post '/admin/tags' do
  add_tag params[:tag_name], params[:tag_purpose_id]

  redirect '/admin/tags'
end

# Update a tag
#
# @param [Integer] id, the id of the tag
# @param [String] tag_name, the new name of the tag
# @param [Integer] tag_purpose_id, the new tag purpose id
#
# @see Model#database_edit_tag
post '/admin/tags/:id/update' do
  update_tag params[:id], params[:name], params[:purpose_id]

  redirect '/admin/tags'
end

# Remove a tag
#
# @param [Integer] id, The id for the tag
post '/admin/tags/:id/delete' do
  remove_tag params[:id]

  redirect '/admin/tags'
end

# Create a new tag purpose
#
post '/admin/tag-purposes' do
  add_tag_purpose params[:tag_purpose_name]

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
  apply_cooldown '/register' if cooldown?

  if error = register_user(params[:username], params[:password], params[:repeat_password])
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

  if user_id = login(params[:username], params[:password])
    # Successful login!
    session[:user_id] = user_id
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
  session[:user_id] = nil

  redirect '/'
end

# Attempt to change a users username
#
# @params [String] username, the username
#
# @see Model#change_username
post '/user/editusername' do
  apply_cooldown '/user' if cooldown?

  user_id = session[:user_id]
  username = params[:username]

  flash[:notice] = if change_username user_id, username
                     'Username successfully changed!'
                   else
                     'Username already taken'
                   end

  redirect '/user'
end

# Attempt to change your password
#
# @params [String] password, your new password
# @params [String] repeat_password, same password another time to make sure you remember it
#
# @see Model#change_password
post '/user/editpassword' do
  apply_cooldown '/user' if cooldown?

  user_id = session[:user_id]

  password = params[:password]
  repeat_password = params[:repeat_password]

  error = change_password user_id, password, repeat_password

  flash[:notice] = error || 'Password successfully changed!'

  redirect '/user'
end

# Delete the current user
#
# @see Model#delete_user
post '/user/delete' do
  delete_user session[:user_id]
  session[:user_id] = nil
  flash[:notice] = 'User successfully deleted'

  redirect '/'
end

# Delete a user
#
# @see Model#delete_user
post '/admin/users/:id/delete' do
  user_id = params[:id].to_i

  # Oh no, the admin is suicidal.
  raise "But sir, that's suicide" if user_id.zero?

  delete_user user_id
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
