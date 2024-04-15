# frozen_string_literal: true

get('/register') do
  erb :'users/register'
end

get('/login') do
  erb :'users/login'
end

# user routes
get('/user') do
  erb(:'users/edit', locals: {
        user: @database.select('user', 'id', user_id)
      })
end

get('/admin/users') do
  erb(:'users/index', locals: {
        users: @database.all_of('user').drop(1)
      })
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

  if error = @database.register(
    params[:username],
    params[:password],
    params[:repeat_password]
  )
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
    change_user_id(id)
    redirect '/games'
  else
    flash[:notice] = 'Invalid login credentials'
    redirect '/login'
  end
end

# Logout a user and redirect to homepage
#
post '/logout' do
  session[:user_id] = nil

  redirect '/games'
end

# Attempt to change a users username
#
# @params [String] username, the username
#
# @see Model#change_username
post '/user/username/update' do
  cooldown_check '/user'

  flash[:notice] = @database.change_username(user_id, params[:username]) || 'Username successfully changed!'

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

  unless @database.login(
    @database.user(user_id)['name'],
    params[:current_password]
  )
    flash[:notice] = 'Wrong password'
    redirect '/user'
  end

  error = @database.change_password(
    user_id,
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
  if flash[:notice] = @database.delete_user(user_id)
    redirect '/user'
  else
    flash[:notice] = 'User successfully deleted'
    session[:user_id] = nil
    redirect '/games'
  end
end

# Delete a user
#
# @see Model#delete_user
post '/admin/users/:id/delete' do
  flash[:notice] = 'User successfully deleted' unless flash[:notice] = @databse.delete_user(params_id)

  redirect '/admin/users'
end
