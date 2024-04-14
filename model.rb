require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

# Model
module Model
  def database(instruction)
    db = SQLite3::Database.new 'data/db.db'
    db.results_as_hash = true
    db.execute 'PRAGMA foreign_keys=ON'
    db.execute instruction
  end

  # Hmmm, validering kan vara något att tänka på
  def games() database('SELECT * FROM game') end
  def game(id) games.map { |game| nil unless game['id'] == id }.compact.first end
  def game_iframe_sizes(id) game_tags(id).map { |tag| tag['purpose'] == 'iframe_size' ? tag['name'] : nil }.compact end
  def game_available_tags(id) tags - game_tags(id) end
  def game_tag_purposes(id) game_tags(game_id).map { |tag| tag['purpose_name'] } end
  def game_tags(id) database('SELECT tag_id FROM game_tag_rel WHERE game_id = ?', id).map { |e| tag(e['tag_id']) } end

  def tags() database 'SELECT id, name, tag.purpose_id as purpose_id, tag_purpose.name as purpose FROM tag LEFT JOIN tag_purpose ON tag_purpose.id = tag.tag_purpose_id' end
  def tag(id) tags.map { |tag| nil unless tag['id'] == tag_id }.compact.first end
  def add_tag(name, purpose_id) database('INSERT INTO tag (name, purpose_id) VALUES (?, ?)', tag_name, tag_purpose_id) end
  def update_tag(id, name, purpose_id) database('UPDATE tag SET name = ?, purpose_id = ? WHERE id = ?', tag_name, tag_purpose_id, tag_id) end
  def delete_tag(id) database('DELETE FROM tag WHERE id = ?', tag_id) end
  def tag_purposes() database('SELECT * FROM tag_purpose') end
  def add_tag_purpose(purpose) database('INSERT INTO tag_purpose (name) VALUES (?)', purpose) end

  def username(id) database('SELECT user.username FROM user WHERE id = ?', user_id).first['username'] end
  def username_exists?(username) !database('SELECT id FROM user WHERE username = ?', username).empty? end
  def user_id_exists?(id) username_exists?(username(user_id)) end
  def user(id) users.map { |user| nil unless user['id'] = id }.compact.first end
  def user_with_name(username) users.map { |user| nil unless user['username'] == username }.compact.first end
  def users() database('SELECT * FROM user').drop(1) end

  # Checks for password problems
  #
  # @return [String] an error message, nil if no errors were encountered
  def validate_password(password, repeat_password)
    return 'You need to type a password' if password.empty?
    return 'Your password needs to be at least 8 characters long' if password.length < 8
    return 'Your password needs a number' if password !~ /[0-9]/
    return 'Your password needs a capital letter' if password !~ /[A-Z]/
    return 'Your password needs at least one special character: #?!@$%^&*-' if password !~ /[#?!@$ %^&*-]/
    return 'Your password\'s don\'t match' if password != repeat_password
  end

  # Attempts to create a new user
  #
  # @params [String] username The username
  # @params [String] password The password
  # @params [String] repeat_password The repeated password
  #
  # @return [String] the error message, nil if no error occured
  def register_user(username, password, repeat_password)
    if username.empty?
      'You need to type a username'
    elsif username == 'admin'
      'Lmao, bro really though he could be admin'
    elsif username_exists? username
      'Username taken, choose another username'
    elsif error = validate_password(password, repeat_password)
      error
    else
      # No error occured. Register the user
      password_digest = BCrypt::Password.create password

      # Add the user to the database
      database 'INSERT INTO user (username, digest, permission_level) VALUES (?, ?, ?)', username, password_digest, 'user'
    end
  end

  # Attempts to login
  #
  # @params [String] username The username
  # @params [String] password The password
  #
  # @return [Integer] the users id, nil if the login was unsuccessful
  def login(username, password)
    # Funderar på att ha felmeddelanden för olika fel. Till exempel ett för om användaren inte finns, ett om lösenordet
    # är fel. Men jag tror det är säkrare att inte ge någon extra information. Det gör hackning den lilla biten svårare.
    user = user_with_name(username)

    # Username not found
    return nil if user.nil?

    password_digest = user['digest']

    # Wrong password
    return nil if BCrypt::Password.new password_digest != password

    user['id'].to_i
  end

  # Attempts to fetch the users permission level
  #
  # @params [Integer] user_id, The users id
  #
  # @return [String] the users permission level (admin/user/guest), nil if the user wasn't found
  def user_permission_level(id)
    # Det kan vara ett säkerhetshål att vem som helst kan komma åt vem som helst permission_level.
    # Borde inte gå i och med hur app.rb hanterar det. Men något at tänka på.
    user = user(id)

    # No user found
    return nil if user.nil?

    # Borde inte kunna vara nil eftersom NN ("Not Null") är checkad i sqlite3 databasen
    user['permission_level']
  end

  # Change a username
  #
  # @param user_id [Integer] the users id
  # @param username [String] the new username
  #
  # @return [Bool] if it was successfull or not
  def change_username(id, username)
    return false if !user_id_exists?(user_id) || username_exist?(username)

    database 'UPDATE user SET username = ? WHERE id = ?', username, id

    true
  end

  # Change your password
  #
  # @param user_id [Integer] the users id
  # @param password [String] new password
  #
  # @return [String] error with password, nil if password is fine
  def change_password(id, password, repeat_password)
    if error = validate_password(password, repeat_password)
      error
    else
      database.execute('UPDATE user SET digest = ? WHERE id = ?', BCrypt::Password.create(password), id)
    end
  end

  # Remove a user
  #
  def delete_user(id)
    raise "No you don't" if id.zero?

    database 'DELETE FROM user WHERE id = ?', id
  end
end
