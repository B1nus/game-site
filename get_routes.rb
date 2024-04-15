# frozen_string_literal: true

# Get routes for my website
module GetRoutes
  def self.included(base)
    # guest routes
    base.get('/') { redirect '/games' }
    base.get('/home') { redirect '/games' }

    base.get('/games') do
      erb(:'games/index', locals: {
            games: database.all_of('game'),
            tags: database.all_of('tag'),
            tag_purposes: database.all_of('tag_purpose')
          })
    end

    base.get('/games/:id') do
      erb(:'games/show', locals: {
            game: database.select('game', 'id', params_id),
            iframe_size: database.game_iframe_sizes(params_id).first
          })
    end

    base.get('/register') do
      erb :'users/register'
    end

    base.get('/login') do
      erb :'users/login'
    end

    # user routes
    base.get('/user') do
      erb(:'users/edit', locals: {
            user: database.select('user', 'id', user_id)
          })
    end

    # admin routes
    base.get('/admin/games/new') do
      erb :'games/new'
    end

    base.get('/admin/games/:id/edit') do
      erb(:'games/edit', locals: {
            game: database.select('game', 'id', params_id),
            game_tags: database.game_tags(params_id),
            tags: database.all_of('tag')
          })
    end

    base.get('/admin/tags/new') do
      erb(:'tags/new', locals: { purposes: database.all_of('tag_purpose') })
    end

    base.get('/admin/tags/:id/edit') do
      erb(:'tags/edit', locals: {
            tag: database.select('tag', 'id', params_id),
            tag_purposes: database.all_of('tag_purpose')
          })
    end

    base.get('/admin/tags/:id') do
      erb(:'tags/show', locals: {
            tag: database.select('tag', 'id', params_id)
          })
    end

    base.get('/admin/tags') do
      erb(:'tags/index', locals: {
            tags: database.all_of('tag'),
            tag_purposes: database.all_of('tag_purpose')
          })
    end

    base.get('/admin/users') do
      erb(:'users/index', locals: {
            users: database.all_of('user').drop(1)
          })
    end
  end
end
