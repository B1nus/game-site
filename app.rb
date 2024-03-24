# frozen_string_literal: true

require 'erb'
require './model'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'slim'

# Länk för att komma in på hemsidan snabbt under testning (:
p('http://localhost:4567/')

# Tillåt sessions. Jag använder det endast för inloggning
enable(:sessions)

# Yardoc
include(Model)

# Validate admin sites
#
before('/admin/*') do
  # Check if the user is logged in at all.
  return 'No admin for you' if session[:user_id].nil?

  # Check if the user is not the first (I am the only admin)
  return 'No admin for you' if session[:user_id] != 1

  # TODO! Implement a check with the database for the permission level (check for == 'admin')
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

  slim(:'games/index')
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

  # Alla attribut från alla spel är publika!!!
  @game = database_game_with_id(game_id)

  # Ganska dumt att bara ta den första. Men kommer fungera så....
  game_iframe_size_string = database_game_iframe_size(game_id).first
  if game_iframe_size_string != nil
    @iframe_size_css = game_iframe_size_string
  else
    # Standard storlek på iframe om inget specifieras
    @iframe_size_css = 'width: 800px; height: 550px;'
  end

  @allow_fullscreen = database_game_tag_purposes(game_id).include?('game_supports_fullscreen')

  slim(:'games/show')
end

# [ADMIN] Formulär för att lägga till en ny tag.
get('/tags/new') do
  # ONLY AS ADMIN

  # För att se vad tag purpose id:n står för
  @tag_purposes = database_tag_purposes

  erb(:'tags/new')
end

# [ADMIN] Add a new tag.
post('/tags') do
  # ONLY AS ADMIN
  tag_name = params[:tag_name]
  tag_purpose_id = params[:tag_purpose_id]

  database_create_tag(tag_name, tag_purpose_id)

  redirect('/tags/')
end

# [ADMIN] Formulär för att ändra en tag.
get('/tags/:id/edit') do
  # ONLY AS ADMIN
  @tag_id = params[:id]

  tag = database_tag_with_id(@tag_id)

  # För att placera föregående värden
  @tag_name = tag['tag_name']
  @tag_purpose_id = tag['tag_purpose_id']

  # För att se vad tag purpose id:n står för
  @tag_purposes = database_tag_purposes

  erb(:'tags/edit')
end

# [ADMIN] Ändra en tag.
post('/tags/:id/update') do
  # ONLY AS ADMIN
  tag_id = params[:id]
  tag_name = params[:tag_name]
  tag_purpose_id = params[:tag_purpose_id]

  database_edit_tag(tag_id, tag_name, tag_purpose_id)

  redirect('/tags/')
end

# [ADMIN] Display all tags. (admin på grund utav edit och delete knappen)
get('/tags/') do
  @tags = database_tags

  slim(:'tags/index')
end

# Visa en tag. (FÅR INTE VARA FÖRE ROUTEN /tags/new!!!)
get('/tags/:id') do
  @tag = database_tag_with_id(params[:id])

  slim(:'tags/show', locals: { tag: @tag })
end

# [ADMIN] Ta bort en tag.
post('/tags/:id/delete') do
  tag_id = params[:id]

  delete_tag(tag_id)

  redirect('/tags/')
end

# Visa listan för tag syften
get('/tag-purposes/') do
  @tag_purposes = database_tag_purposes

  slim(:'tag-purposes/index')
end

# Formulär för att skapa ett nytt tag syfte
get('/tag-purposes/new') do
  slim(:'tag-purposes/new')
end

# [ADMIN] Skapa ett nytt tag Syfte
post('/tag-purposes') do
  @tag_purpose_name = params[:tag_purpose_name]

  database_create_tag_purpose(@tag_purpose_name)

  redirect('/tag-purposes/')
end

# [ADMIN] Redigera ett spel genom formulär m.m. (följer inte restful routes )
get('/games/:id/edit') do
  @game_id = params[:id]

  # Kanske borde vis alla tags istället för bara de som är kvar.
  @available_tags = database_game_available_tags(@game_id)
  @applied_tags = database_game_applied_tags(@game_id)

  # Samla alla tags i en lista
  @tags = database_tags

  erb(:'games/edit')
end

# Hmmm, jag får bara det sista elementet i selectionen...
post('/games/:id/update') do
  game_id = params[:id]

  tags_selection = params[:tags_selection]
  p tags_selection

  redirect("/games/#{game_id}/edit")
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
  # Glöm inte spam protection
  username = params[:username]
  password = params[:password]

  # TODO! Autentisering i model.rb
end

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
# hur ska jag skilja på user och guest routes fint? Lös senare.
