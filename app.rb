# frozen_string_literal: true

require './model'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'

# Tillåt sessions. Jag använder det endast för inloggning
enable(:sessions)

# Yardoc
include(Model)

# Cooldown hash
$cooldown = {}

helpers do
  def admin?
    admin = !session[:user_id].nil? && session[:user_id].zero? && user_permission_level(session[:user_id]) == 'admin'

    flash[:notice] = 'No admin for you' unless admin

    admin
  end

  def logged_in?
    logged_in = !session[:user_id].nil? && user_id_exists?(session[:user_id]) && session[:user_id] != 0

    flash[:notice] = 'You need to login' unless logged_in

    logged_in
  end

  def cooldown?
    site = request.path_info
    ip = request.ip

    $cooldown = { site => {} } unless $cooldown[site]
    $cooldown[site] = { ip => { count: 0, time: 0 } } unless $cooldown[site][ip]
    $cooldown[site][ip][:count] += 1

    # Alright, you can go for now
    $cooldown[site][ip][:count] = 0 if Time.now.to_i - $cooldown[site][ip][:time] >= 5

    # Calm down there sunny
    $cooldown[site][ip][:time] = Time.now.to_i

    $cooldown[site][ip][:count] >= 5
  end

  def apply_cooldown(redirect_url)
    flash[:notice] = 'Calm down there, your making to many requests'

    redirect(redirect_url)
  end
end

# Validate admin sites
#
before('/admin/*') do
  redirect('/') unless admin?
end

# Validate user sites
#
before('/user*') do
  redirect('/') unless logged_in?
end

# Display Landing Page
#
get('/') do
  redirect('/games/')
end

# Displays games
#
get('/games/') do
  # Alla attribut från alla spel är publika!!!
  @games = database_games

  @games.each do |game|
    # Kolla efter en tag som varnar för tredjeparts hemsida
    should_warn = database_game_tag_purposes(game['id']).include?('warn_for_stolen_game')

    # Ändra länk beroende på om tagen fanns
    game['url'] = if should_warn
                    "/warning/#{game['id']}"
                  else
                    "/games/#{game['id']}"
                  end
  end

  erb(:'games/index')
end

# Display a warning for games I do not own
#
# @params [String] game_id, The id of the game to warn for
get('/warning/:game_id') do
  game = database_game_with_id(params[:game_id])

  @foreign_url = game['foreign_url']
  @indigenous_url = "/games/#{game['id']}"

  slim(:warning)
end

# Spela ett spel
get('/games/:game_id') do
  game_id = params[:game_id]

  # Någon har hållt på med länkern ser jag
  redirect('/notintegerparam') if game_id.to_i.zero?

  # Alla attribut från alla spel är publika!!!
  @game = database_game_with_id(game_id)

  # Ganska dumt att bara ta den första. Men kommer fungera så....
  game_iframe_size_string = database_game_iframe_size(game_id).first
  @iframe_size_css = if !game_iframe_size_string.nil?
                       game_iframe_size_string
                     else
                       # Standard storlek på iframe om inget specifieras
                       'width: 800px; height: 550px;'
                     end

  @allow_fullscreen = database_game_tag_purposes(game_id).include?('game_supports_fullscreen')

  erb(:'games/show')
end

# Display all games with edit and delete buttons
#
# @see Model#database_games
get('/admin/games/') do
  # Alla attribut från alla spel är publika!!!
  @games = database_games

  @games.each do |game|
    # Kolla efter en tag som varnar för tredjeparts hemsida
    should_warn = database_game_tag_purposes(game['id']).include?('warn_for_stolen_game')

    # Ändra länk beroende på om tagen fanns
    game['url'] = if should_warn
                    "/warning/#{game['id']}"
                  else
                    "/games/#{game['id']}"
                  end
  end

  erb(:'games/index-admin')
end

# Displays a form for editing a game
#
# @param [Integer] id, The id of the game
get('/admin/games/:id/edit') do
  @game_id = params[:id]

  # Kanske borde vis alla tags istället för bara de som är kvar.
  @available_tags = database_game_available_tags(@game_id)
  @applied_tags = database_game_applied_tags(@game_id)

  # Samla alla tags i en lista
  @tags = database_tags

  erb(:'games/edit')
end

# Updates an existing game and redirects to '/admin/games/'
post('/admin/games/:id/update') do
  # game_id = params[:id]
  #
  # tags_selection = params[:tags_selection]

  redirect('/admin/games/')
end

# Displays a form for creating tags
#
get('/admin/tags/new') do
  # För att se vad tag purpose id:n står för
  @tag_purposes = database_tag_purposes

  erb(:'tags/new')
end

post('/admin/tags') do
  tag_name = params[:tag_name]
  tag_purpose_id = params[:tag_purpose_id]

  database_create_tag(tag_name, tag_purpose_id)

  redirect('/admin/tags/')
end

# Displays a form for editing a tag
#
# @param [Integer] tag_id, the id for the tag
#
# @see Model#database_tag_with_id
get('/admin/tags/:id/edit') do
  @tag_id = params[:id]

  tag = database_tag_with_id(@tag_id)

  # För att placera föregående värden
  @tag_name = tag['tag_name']
  @tag_purpose_id = tag['tag_purpose_id']

  # För att se vad tag purpose id:n står för
  @tag_purposes = database_tag_purposes

  erb(:'tags/edit')
end

# Update a tag
#
# @param [Integer] id, the id of the tag
# @param [String] tag_name, the new name of the tag
# @param [Integer] tag_purpose_id, the new tag purpose id
#
# @see Model#database_edit_tag
post('/admin/tags/:id/update') do
  tag_id = params[:id]
  tag_name = params[:tag_name]
  tag_purpose_id = params[:tag_purpose_id]

  database_edit_tag(tag_id, tag_name, tag_purpose_id)

  redirect('/admin/tags/')
end

# Display all tags
#
# @see Model#database_tags
get('/admin/tags/') do
  @tags = database_tags

  erb(:'tags/index')
end

# Display a tag
#
get('/admin/tags/:id') do
  @tag = database_tag_with_id(params[:id])

  erb(:'tags/show')
end

# Remove a tag
#
# @param [Integer] id, The id for the tag
post('/admin/tags/:id/delete') do
  tag_id = params[:id]

  delete_tag(tag_id)

  redirect('/admin/tags/')
end

# Displays all tag purposes
#
get('/admin/tag-purposes/') do
  @tag_purposes = database_tag_purposes

  slim(:'tag-purposes/index')
end

# Displays a form for creating a tag purpose
#
get('/admin/tag-purposes/new') do
  slim(:'tag-purposes/new')
end

# Create a new tag purpose and redirect to '/admin/tag-purposes/'
#
post('/admin/tag-purposes') do
  @tag_purpose_name = params[:tag_purpose_name]

  database_create_tag_purpose(@tag_purpose_name)

  redirect('/admin/tag-purposes/')
end

# Displays a register form. This deviates from RESTFUL ROUTES by design
#
get('/register') do
  erb(:'users/register')
end

# Attempts to register a user
#
# @param [String] username, The username
# @param [String] password, The password
# @param [String] repeat-password, The repeated password
#
# @see Model#register_user
post('/register') do
  apply_cooldown('/register') if cooldown?

  username = params[:username]
  password = params[:password]
  repeat_password = params[:password_validation]

  error = register_user(username, password, repeat_password)

  if error
    flash[:notice] = error
    redirect('/register')
  else
    flash[:notice] = 'Registration successful!'
    redirect('/login')
  end
end

# Displays a login form
#
get('/login') do
  erb(:'users/login')
end

# Attempts to login
#
# @params [String] username, The username
# @params [String] password, The password
#
# @see Model#login
post('/login') do
  apply_cooldown('/login') if cooldown?

  username = params[:username]
  password = params[:password]

  user_id = login(username, password)

  if user_id
    # Successful login!
    session[:user_id] = user_id
    redirect('/')
  else
    # Login failed.
    flash[:notice] = 'Invalid login credentials'
    redirect('/login')
  end
end

# Logout a user and redirect to homepage
#
get('/logout') do
  session[:user_id] = nil

  redirect('/')
end

# Displays a form for editing user info
#
get('/user') do
  @user_id = session[:user_id]
  @username = database_username(@user_id)

  erb(:'users/edit')
end

# Observera att detta är en medveten avvikelse från restful routes

# Attempt to change a users username
#
# @params [String] username, the username
#
# @see Model#change_username
post('/user/editusername') do
  apply_cooldown('/user') if cooldown?

  user_id = session[:user_id]
  username = params[:username]

  flash[:notice] = if change_username(user_id, username)
                     'Username successfully changed!'
                   else
                     'Username already taken'
                   end

  redirect('/user')
end

# Observera att detta är en medveten avvikelse från restful routes

# Attempt to change your password
#
# @params [String] password, your new password
# @params [String] repeat_password, same password another time to make sure you remember it
#
# @see Model#change_password
post('/user/editpassword') do
  apply_cooldown('/user') if cooldown?

  user_id = session[:user_id]

  password = params[:password]
  repeat_password = params[:repeat_password]

  error = change_password(user_id, password, repeat_password)

  flash[:notice] = error || 'Password successfully changed!'

  redirect('/user')
end

# Delete the current user
#
# @see Model#delete_user
post('/user/delete') do
  delete_user(session[:user_id])

  session[:user_id] = nil
  flash[:notice] = 'User successfully deleted'

  redirect('/')
end

# Display all users
#
# @see Model#users
get('/admin/users/') do
  @users = users

  erb(:'users/index')
end

# Delete a user
#
# @see Model#delete_user
post('/admin/users/:user_id/delete') do
  user_id = params[:user_id].to_i

  # Oh no, the admin is suicidal.
  raise "But sir, that's suicide" if user_id.zero?

  delete_user(user_id)

  flash[:notice] = 'User successfully deleted'

  redirect('/admin/users/')
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
