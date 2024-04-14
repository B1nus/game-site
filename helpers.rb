def user_id
  session[:user_id]
end

def change_user_id(id)
  session[:user_id] = id
end

def logout
  session[:user_id] = nil
end

def logged_in?
  !user_id.nil? && user_id_exists?(user_id)
end

def admin?
  logged_in? && user_id.zero? && user_permission_level(user_id) == 'admin'
end

def user?
  logged_in? && user_id != 0 && user_permission_level(user_id) == 'user'
end

def admin_check
  return if admin?

  flash[:notice] = 'No admin for you'
  redirect '/'
end

def user_check
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

def cooldown_check(redirect_url)
  return unless cooldown?

  flash[:notice] = 'Calm down there, your making to many requests'
  redirect redirect_url
end
