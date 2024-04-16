# frozen_string_literal: true

require_relative 'helpers'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

# Model class, this is where interaction with the database takes place.
# By default, methods return nil upon success and error upon failure.
#
# There is no authorization here, the caller is trusted with that responsibility
class Model
  def initialize
    @database = SQLite3::Database.new('data/db.db')
    @database.results_as_hash = true
    @database.execute('PRAGMA foreign_keys = ON')
  end

  def execute(instructions, *injections)
    @database.execute(instructions, *injections)
  end

  def table_check(table)
    raise 'Table name must be a string' unless table.is_a? String
    raise 'Table name can\'t be empty' if table.empty?
    raise "Table #{table} does not exist" if execute(
      "SELECT name FROM sqlite_master WHERE type=\'table\' AND name=?", table
    ).empty?
  end

  def column_exists?(table, column)
    table_check table
    !execute("SELECT * FROM pragma_table_info('#{table}') WHERE name = ?", column).empty?
  end

  def validate_tag(name, purpose_id)
    return 'Tag name must be a string' unless name.is_a? String
    return 'Can\'t give a tag a empty name' if name.empty?
    return 'Purpose id must be a integer' unless purpose_id.is_a? Integer
    return 'Can\'t add a non existent tag purpose' unless select('tag_purpose', 'id', purpose_id)

    nil
  end

  def all_of(table)
    table_check table

    if table == 'tag'
      execute('SELECT tag.id as id FROM tag').map { |tag| select('tag', 'id', tag['id']) }
    else
      execute("SELECT * FROM #{table}")
    end
  end

  def select(table, attribute, value)
    raise "#{attribute} is not a column of the #{table} table" unless column_exists?(table, attribute)

    if table == 'tag'
      execute("SELECT tag.name, tag.id, tag_purpose.name as purpose, purpose_id FROM tag LEFT JOIN
              tag_purpose ON tag_purpose.id = tag.purpose_id WHERE tag.#{attribute} = ?", value)
    else
      execute("SELECT * FROM #{table} WHERE #{attribute} = ?", value)
    end.first
  end

  # Return a user dictionary
  #
  # @param identifier [String or Integer] the name of the user or Integer for user id
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

  # All tags for a game
  #
  # @param id [Integer] the id for the game
  #
  # @return [Hash] key :error for a error message, nil if no error, key :tags for array of tags, nil if error
  def game_tags(id)
    return { error: 'Non integer game id is not allowed' } unless id.is_a? Integer
    return { error: 'Can\'t find tags for non existent game' } if select('game', 'id', id).nil?

    tags = execute('SELECT tag as id FROM game_tag_rel WHERE game = ?', id).map { |tag| select('tag', 'id', tag['id']) }

    { tags: }
  end

  def add_tag(name, purpose_id)
    return validate_tag(name, purpose_id) if validate_tag(name, purpose_id)

    nil if execute('INSERT INTO tag (name, purpose_id) VALUES (?, ?)', name, purpose_id)
  end

  def add_user(username, password)
    return 'Username must be a string' unless username.is_a? String
    return 'Password must be a string' unless password.is_a? String
    return 'Username can\'t be empty' if username.empty?
    return 'Password can\'t be empty' if password.empty?
    return 'Username is already taken' if user_exists? username

    # No error occured. Register the user
    digest = BCrypt::Password.create(password)

    nil if execute('INSERT INTO user (name, digest, domain) VALUES (?, ?, ?)', username, digest, 'user')
  end

  def add_tag_purpose(purpose)
    return 'Tag purpose name must be a string' unless purpose.is_a? String
    return 'Tag purpose name can\'t be empty' if purpose.empty?

    nil if execute('INSERT INTO tag_purpose (name) VALUES (?)', purpose)
  end

  def delete_user(id)
    return 'Non integer user id is not allowed' unless id.is_a? Integer
    return 'Can\'t delete a non existent user' unless user_exists?(id)
    return 'No you don\'t' if id.zero?

    nil if execute('DELETE FROM user WHERE id = ?', id)
  end

  def delete_tag(id)
    return 'Non integer tag id is not allowed' unless id.is_a? Integer
    return 'Can\'t delete a non existent tag' unless select('tag', 'id', id)

    nil if execute('DELETE FROM tag WHERE id = ?', id)
  end

  # All iframe sizes for a game
  #
  # @param id [Integer] the id for the game
  #
  # @return [Hash] key :error for a error message, nil if no error, key :sizes for size array, nil if error
  def game_sizes(id)
    tags = game_tags(id)

    return tags if tags[:error]
    return { error: 'Unknown error, report this so I can fix it!' } unless tags[:tags]

    tags = [:tags].map { |tag| tag['purpose'] == 'size' ? tag['name'] : nil }.compact

    { sizes: tags }
  end

  def update_tag(id, name, purpose_id)
    return 'Non integer tag id is not allowed' unless id.is_a? Integer
    return 'Can\'t update a non existent tag' unless select('tag', 'id', id)
    return validate_tag(name, purpose_id) if validate_tag(name, purpose_id)

    nil if execute('UPDATE tag SET name = ?, purpose_id = ? WHERE id = ?', name, purpose_id, id)
  end

  # Checks for password problems with a repeated password
  #
  # @param password [String] the password
  # @param repeat_password [String] the password again (hopefully) to make sure no errors were made
  #
  # @return [String] an error message, nil if no errors were encountered
  def validate_passwords(password, repeat_password)
    return validate_password(password) if validate_password(password)
    return 'You need to repeat your password' if repeat_password.empty?
    return 'Your password\'s don\'t match' if password != repeat_password

    nil
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
    return 'Your password needs at least one special character: #?!@$%^&*-' if password !~ /[#?!@$ %^&*-]/

    nil
  end

  # Attempts to create a new user
  #
  # @param [String] username The username
  # @param [String] password The password
  # @param [String] repeat_password The repeated password
  #
  # @return [String] the error message, nil if no error occured
  def register(username, password, repeat_password)
    return 'You need to type a username' if username.empty?
    return 'Username is already taken' if user username
    return validate_passwords(password, repeat_password) if validate_passwords(password, repeat_password)

    add_user(username, password)
  end

  # Attempts to login
  #
  # @param [String] name, the username
  # @param [String] password
  #
  # @return [Hash] key :id for the users id, nil if error. Key :error for a error message, nil for success
  def login(name, password)
    return { error: 'Username and password must be strings' } if !name.is_a?(String) || !password.is_a?(String)

    user = user name

    return { error: 'Invalid login credentials' } if user.nil?
    return { error: 'Invalid login credentials' } if BCrypt::Password.new(user['digest']) != password

    { id: user['id'] }
  end

  # Change a username
  #
  # @param id [Integer] the users id
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
  # @param id [Integer] the users id
  # @param password [String] new password
  #
  # @return [String] error with password, nil if password is fine
  def change_password(id, password, repeat_password)
    return "Can't find user with id #{id}" unless user = user(id)
    return 'Your new password can\'t be the same as your old password' if BCrypt::Password.new(
      user['digest']
    ) == password

    return validate_passwords(password, repeat_password) if validate_passwords(password, repeat_password)

    nil if execute('UPDATE user SET digest = ? WHERE id = ?', BCrypt::Password.create(password), id)
  end
end
