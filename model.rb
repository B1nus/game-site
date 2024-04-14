require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

# Model
module Model
  def database(instruction, *injections)
    db = SQLite3::Database.new('data/db.db')
    db.results_as_hash = true
    db.execute('PRAGMA foreign_keys=ON')
    db.execute(instruction, *injections)
  end

  # Lite läskigt att det inte finns någon säkerhet i model.rb, jag litar på att app.rb hanterar admin och user behörigheter.

  # Maybe move these types of functions to a new utils.rb file?
  def with_id(array, id) id.is_a?(Integer) ? with_attribute(array, 'id', id) : raise('Non integer id') end
  def with_attribute(array, attribute, value) array.detect { |e| e[attribute] == value } end

  def user(id) with_id(users, id) end
  def game(id) with_id(games, id) end
  def tag(id) with_id(tags, id) end

  def games() database('SELECT * FROM game') end
  def users() database('SELECT * FROM user') end
  def tag_purposes() database('SELECT * FROM tag_purpose') end
  def tags() database('SELECT tag.id as id, tag.name as name, tag.tag_purpose_id as purpose_id, tag_purpose.name as purpose FROM tag LEFT JOIN tag_purpose ON tag_purpose.id = tag.tag_purpose_id') end

  def add_tag(name, purpose_id) database('INSERT INTO tag (name, purpose_id) VALUES (?, ?)', name, purpose_id) end
  def add_user(username, digest) database('INSERT INTO user (username, digest, permission_level) VALUES (?, ?, ?)', username, digest, 'user') end
  def add_tag_purpose(purpose) database('INSERT INTO tag_purpose (name) VALUES (?)', purpose) end

  def delete_user(id) id.zero? ? raise('No you don\'t') : database('DELETE FROM user WHERE id = ?', id) end
  def delete_tag(id) database('DELETE FROM tag WHERE id = ?', id) end

  # Hmmm, validering kan vara något att tänka på
  def game_iframe_sizes(id) game_tags(id).map { |tag| tag['purpose'] == 'iframe_size' ? tag['name'] : nil }.compact end
  def game_available_tags(id) tags - game_tags(id) end
  def game_tag_purposes(id) game_tags(id).map { |tag| tag['purpose_name'] } end
  def game_tags(id) database('SELECT tag_id as id FROM game_tag_rel WHERE game_id = ?', id).map { |e| tag(e['id']) } end

  def update_tag(id, name, purpose_id) database('UPDATE tag SET name = ?, purpose_id = ? WHERE id = ?', name, purpose_id, id) end

  def username(id) user(id)['username'] end
  def user_with_name(username) with_attribute(users, 'username', username) end
  def user_permission_level(id) user(id).instance_eval { |user| user['permission_level'] if user } end
  def username_exists?(username) !user_with_name(username).nil? end
  def user_id_exists?(id) !user(id).nil? end

  # Checks for password problems
  #
  # @param password [String] the password
  # @param repeat_password [String] the password again (hopefully) to make sure no errors were made
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
  # @param [String] username The username
  # @param [String] password The password
  # @param [String] repeat_password The repeated password
  #
  # @return [String] the error message, nil if no error occured
  def register_user(username, password, repeat_password)
    return 'You need to type a username' if username.empty?
    return 'Lmao, bro really though he could be admin' if username == 'admin'
    return 'Username taken, choose another username' if username_exists? username
    return if validate_password(password, repeat_password)

    # No error occured. Register the user
    digest = BCrypt::Password.create password

    # Add the user to the database
    add_user(username, digest)
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

    return nil unless user

    digest = user['digest']

    BCrypt::Password.new(digest) != password ? nil : user['id']
  end

  # Change a username
  #
  # @param user_id [Integer] the users id
  # @param username [String] the new username
  #
  # @return [Bool] if it was successfull or not
  def change_username(id, username)
    if user_id_exists?(user_id) && !username_exist?(username)
      database 'UPDATE user SET username = ? WHERE id = ?', username, id
      true
    end

    false
  end

  # Change your password
  #
  # @param user_id [Integer] the users id
  # @param password [String] new password
  #
  # @return [String] error with password, nil if password is fine
  def change_password(id, password, repeat_password)
    validate_password(password, repeat_password).instance_eval do |error|
      error || database.execute('UPDATE user SET digest = ? WHERE id = ?', BCrypt::Password.create(password), id)
    end
  end
end
