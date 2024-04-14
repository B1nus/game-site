# frozen_string_literal: true

def params_id
  id = params[:id].to_i

  raise 'That id is not an integer' if id.zero? || id.nil?

  id
end

def user_id
  session[:user_id]
end

def change_user_id(id)
  session[:user_id] = id
end

def delete_user(id)
  @database.delete_user(id)
  flash[:notice] = 'User successfully deleted'
end

def logout
  session[:user_id] = nil
end

def logged_in?
  !user_id.nil? && @database.user_exists?(user_id)
end

def admin?
  logged_in? && user_id.zero? && @database.user(user_id)['domain'] == 'admin'
end

def user?
  logged_in? && user_id != 0 && @database.user(user_id)['domain']  == 'user'
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

# Cooldown hash
$requests = {}
COOLDOWN_COUNT_LIMIT = 5 # Max number of requests
COOLDOWN_COUND_RESET_TIME = 5 # Time when the count is reset
def cooldown?
  site = request.path_info
  ip = request.ip

  $requests[site] ||= {}
  current_ip_data = $requests[site][ip] || { count: 0, time: 0 }

  current_ip_data[:count] += 1
  current_ip_data[:count] = 0 if Time.now.to_i - current_ip_data[:time] >= COOLDOWN_COUND_RESET_TIME
  current_ip_data[:time] = Time.now.to_i

  $requests[site][ip] = current_ip_data

  current_ip_data[:count] >= COOLDOWN_COUNT_LIMIT
end

def cooldown_check(redirect_url)
  return unless cooldown?

  flash[:notice] = 'Calm down, your making to many requests'
  redirect redirect_url
end
