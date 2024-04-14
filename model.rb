# frozen_string_literal: true

require './helpers'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

# Läskigt att det inte finns någon säkerhet i model.rb, jag måste lita på att app.rb hanterar behörigheter.
#
# Funderar på noggrann validering på login, kan vara bättre utan det så man ger hackare så lite information som möjligt

# Model class, this is where interaction with the database takes place
class Model
  def initialize
    @database = SQLite3::Database.new('data/db.db')
    @database.results_as_hash = true
    @database.execute('PRAGMA foreign_keys = ON')
  end

  def execute(instructions, *injections)
    @database.execute(instructions, *injections)
  end

  def all_of(table)
    # Insert validation of table here. Reuse for Model#select as well, DRY
    if table == 'tag'
      execute('SELECT tag.id as id FROM tag').map { |tag| select('tag', 'id', tag['id']) }
    else
      execute("SELECT * FROM #{table}")
    end
  end

  def select(table, attr, val)
    # Insert validation of table, attr and val here
    if table == 'tag'
      execute("SELECT tag.name, tag.id, tag_purpose.name as purpose, purpose_id FROM tag LEFT JOIN
              tag_purpose ON tag_purpose.id = tag.purpose_id WHERE tag.#{attr} = ?", val)
    else
      execute("SELECT * FROM #{table} WHERE #{attr} = ?", val)
    end.first
  end

  # Return a user dictionary
  #
  # @param [String or Integer] String for username, Integer for user id
  def user(identifier)
    if identifier.is_a? Integer
      select('user', 'id', identifier)
    elsif identifier.is_a? String
      select('user', 'name', identifier)
    end
  end

  def user_exists?(identifier)
    !user(identifier).nil?
  end

  def game_tags(id)
    execute('SELECT tag as id FROM game_tag_rel WHERE game = ?', id).map { |tag| tag(tag['id']) }
  end

  def add_tag(name, purpose_id)
    execute('INSERT INTO tag (name, purpose_id) VALUES (?, ?)', name, purpose_id)
  end

  def add_user(username, digest)
    execute('INSERT INTO user (username, digest, domain) VALUES (?, ?, ?)', username, digest, 'user')
  end

  def add_tag_purpose(purpose)
    execute('INSERT INTO tag_purpose (name) VALUES (?)', purpose)
  end

  def delete_user(id)
    id.zero? ? raise('No you don\'t') : execute('DELETE FROM user WHERE id = ?', id)
  end

  def delete_tag(id)
    execute('DELETE FROM tag WHERE id = ?', id)
  end

  # Hmmm, validering kan vara något att tänka på
  def game_iframe_sizes(id)
    game_tags(id).map { |tag| tag['purpose'] == 'iframe_size' ? tag['name'] : nil }.compact
  end

  def update_tag(id, name, purpose_id)
    execute('UPDATE tag SET name = ?, purpose_id = ? WHERE id = ?', name, purpose_id, id)
  end

  # Checks for password problems with a repeated password
  #
  # @param password [String] the password
  # @param repeat_password [String] the password again (hopefully) to make sure no errors were made
  #
  # @return [String] an error message, nil if no errors were encountered
  def validate_passwords(password, repeat_password)
    return if validate_password(password)
    return 'You need to repeat your password' if repeat_password.empty?

    'Your password\'s don\'t match' if password != repeat_password
  end

  # Checks for password problems for a single password
  #
  # @param password [String]
  #
  # @return [String] error or nil if no error
  def validate_password(password)
    return 'You need to type a password' if password.empty?
    return 'Your password needs to be at least 8 characters long' if password.length < 8
    return 'Your password needs a number' if password !~ /[0-9]/
    return 'Your password needs a capital letter' if password !~ /[A-Z]/

    'Your password needs at least one special character: #?!@$%^&*-' if password !~ /[#?!@$ %^&*-]/
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
    return unless validate_passwords(password, repeat_password)

    # No error occured. Register the user
    digest = BCrypt::Password.create password

    # Add the user to the database
    nil if add_user(username, digest)
  end

  # Attempts to login
  #
  # @params [String] username The username
  # @params [String] password The password
  #
  # @return [Integer] the users id, nil if the login was unsuccessful
  def login(username, password)
    # No user found, no other checks should be necessary since NOT NULL is enforced by the database
    return unless user = user(username)

    BCrypt::Password.new(user['digest']) != password ? nil : user['id']
  end

  # Change a username
  #
  # @param user_id [Integer] the users id
  # @param username [String] the new username
  #
  # @return [String] error or nil if nothing went wrong
  def change_username(id, username)
    # Insert id validation here

    # return 'You don\'t exist' unless user_exists?(id)
    return 'Username is already taken' if user_exists?(username)

    execute('UPDATE user SET name = ? WHERE id = ?', username, id)

    nil
  end

  # Change your password
  #
  # @param user_id [Integer] the users id
  # @param password [String] new password
  #
  # @return [String] error with password, nil if password is fine
  def change_password(id, password, new_password, repeat_new_password)
    return 'Incorrect password' unless login(user(id)['name'], password)
    return 'Your new password can\'t be the same as old password' if password == new_password

    error = validate_passwords(new_password, repeat_new_password)

    return error if error

    execute('UPDATE user SET digest = ? WHERE id = ?', BCrypt::Password.create(new_password), id)

    nil
  end
end
