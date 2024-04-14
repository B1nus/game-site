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
database = Model.new

on_start { puts 'Server started as http://localhost:4567' }
on_stop { puts 'By Bye!' }

# Needed to expose the database to my './helper.rb' file
before('*') { @database = database }

# Protect admin and user sites
before('/admin/*') { admin_check }
before('/user*') { user_check }

# One liner get routes.

# guest
get('/') { redirect '/games' }
get('/games') do
  erb(:'games/index', locals: {
        games: database.all_of('game'),
        tags: database.all_of('tag'),
        tag_purposes: database.all_of('tag_purpose')
      })
end
get('/games/:id') do
  erb(:'games/show', locals: {
        game: database.select('game', 'id', params_id),
        iframe_size: database.game_iframe_sizes(params_id).first
      })
end
get('/register') { erb :'users/register' }
get('/login') { erb :'users/login' }
# user
get('/user') { erb(:'users/edit', locals: { user: database.select('user', 'id', user_id) }) }
# admin
get('/admin/games/new') { erb :'games/new' }
get('/admin/games/:id/edit') do
  erb(:'games/edit', locals: {
        game: database.select('game', 'id', params_id),
        game_tags: database.game_tags(params_id),
        tags: database.all_of('tag')
      })
end
get('/admin/tags/new') { erb(:'tags/new', locals: { purposes: database.all_of('tag_purpose') }) }
get('/admin/tags/:id/edit') do
  erb(:'tags/edit', locals: {
        tag: database.select('tag', 'id', params_id),
        tag_purposes: database.all_of('tag_purpose')
      })
end
get('/admin/tags/:id') { erb(:'tags/show', locals: { tag: database.select('tag', 'id', params_id) }) }
get('/admin/tags') do
  erb(:'tags/index', locals: {
        tags: database.all_of('tag'),
        tag_purposes: database.all_of('tag_purpose')
      })
end
get('/admin/users') { erb(:'users/index', locals: { users: database.all_of('users') }) }

# Updates an existing game and redirects to '/admin/games'
post '/admin/games/:id/update' do
  # game_id = params_id
  #
  # tags_selection = params[:tags_selection]

  redirect '/admin/games'
end

# Add a new tag
#
# @param tag_name [String]
# @param tag_purpose_id [Integer]
post('/admin/tags') do
  if params[:name].empty?
    flash[:notice] = 'The new tag name can\'t be empty'
    redirect '/'
  end

  database.add_tag(params[:name], params[:purpose_id].to_i)
  redirect '/'
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
    redirect '/'
  end

  database.update_tag(params_id, params[:name], params[:purpose_id])
  redirect '/'
end

# Remove a tag
#
# @param [Integer] id, The id for the tag
post('/admin/tags/:id/delete') do
  database.delete_tag(params_id)
  redirect '/'
end

# Create a new tag purpose
#
post('/admin/tag-purposes') do
  if params[:purpose].empty?
    flash[:notice] = 'A tag purpose name can\'t be empty'
    redirect '/'
  end

  database.add_tag_purpose(params[:purpose])
  redirect '/'
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

  flash[:notice] = database.change_username(user_id, params[:username]) || 'Username successfully changed!'

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

  redirect '/'
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
