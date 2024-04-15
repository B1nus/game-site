# frozen_string_literal: true

get('/') do
  redirect '/games'
end

get('/home') do
  redirect '/games'
end

get('/games') do
  erb(:'games/index', locals: {
        games: @database.all_of('game'),
        tags: @database.all_of('tag'),
        tag_purposes: @database.all_of('tag_purpose')
      })
end

get('/games/:id') do
  erb(:'games/show', locals: {
        game: @database.select('game', 'id', params_id),
        iframe_size: @database.game_iframe_sizes(params_id).first
      })
end

get('/admin/games/new') do
  erb :'games/new'
end

get('/admin/games/:id/edit') do
  erb(:'games/edit', locals: {
        game: @database.select('game', 'id', params_id),
        game_tags: @database.game_tags(params_id),
        tags: @database.all_of('tag')
      })
end

# Updates an existing game and redirects to '/admin/games'
post '/admin/games/:id/update' do
  # name = params[:name]
  # tag_ids = params[:tags]
  # fullscreen = !params[:fullscreen].nil?
  # warning = !params[:warning].nil?
  # time_created = ???

  redirect '/games'
end
