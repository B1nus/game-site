require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

# Model
module Model
  def database
    db = SQLite3::Database.new('data/db.db')
    db.results_as_hash = true
    db
  end

  def database_games
    database.execute('SELECT * FROM game')
  end

  def database_game_with_id(game_id)
    database.execute('SELECT * FROM game WHERE id = ?', game_id).first
  end

  def database_game_iframe_size(game_id)
    database.execute(
      'SELECT tag.name as tag_name FROM game_tag_rel INNER JOIN tag ON tag.id = tag_id INNER JOIN tag_purpose ON
      tag_purpose_id = tag_purpose.id WHERE game_id = ? AND tag_purpose.name = \'iframe_size\'', game_id
    ).map { |e| e['tag_name'] }
  end

  def database_game_applied_tags(game_id)
    database.execute(
      'SELECT tag.id as tag_id, tag.name as tag_name, tag.tag_purpose_id, tag_purpose.name as tag_purpose_name FROM
      game_tag_rel RIGHT JOIN tag ON game_tag_rel.tag_id = tag.id LEFT JOIN tag_purpose ON tag_purpose.id =
      tag_purpose_id WHERE game_id = ?', game_id
    )
  end

  def database_game_available_tags(game_id)
    database.execute(
      'SELECT t.id as tag_id, t.name as tag_name, tag_purpose_id, tag_purpose.name as tag_purpose_name FROM tag LEFT
      JOIN game_tag_rel gtr ON t.id = gtr.tag_id AND gtr.game_id = ? LEFT JOIN tag_purpose ON tag_purpose.id =
      tag_purpose_id WHERE gtr.game_id IS NULL;', game_id
    )
  end

  def database_game_tag_purposes(game_id)
    database.execute(
      'SELECT tag_purpose.name FROM game_tag_rel INNER JOIN tag ON game_tag_rel.tag_id = tag.id INNER JOIN tag_purpose
      ON tag.tag_purpose_id = tag_purpose.id WHERE game_id = ?', game_id
    ).map { |e| e['name'] }
  end

  def database_tags
    database.execute(
      'SELECT tag.id as tag_id, tag.name as tag_name, tag.tag_purpose_id, tag_purpose.name as tag_purpose_name FROM tag
      LEFT JOIN tag_purpose ON tag_purpose.id = tag.tag_purpose_id'
    )
  end

  def database_tag_with_id(tag_id)
    database.execute(
      'SELECT tag.id as id, tag.name as tag_name, tag_purpose_id, tag_purpose.name as tag_purpose_name FROM tag
      LEFT JOIN tag_purpose ON tag_purpose.id = tag.tag_purpose_id WHERE tag.id = ?',
      tag_id
    ).first
  end

  def database_create_tag(tag_name, tag_purpose_id)
    database.execute('INSERT INTO tag (name, tag_purpose_id) VALUES (?, ?)', tag_name, tag_purpose_id)
  end

  def database_edit_tag(tag_id, tag_name, tag_purpose_id)
    database.execute('UPDATE tag SET name = ?, tag_purpose_id = ? WHERE id = ?', tag_name, tag_purpose_id, tag_id)
  end

  def delete_tag(tag_id)
    database.execute('DELETE FROM tag WHERE id = ?', tag_id)
  end

  # Lista över alla tag syften
  def database_tag_purposes
    database.execute('SELECT * FROM tag_purpose')
  end

  # Lägg till ett tag syfte
  def database_create_tag_purpose(tag_purpose_name)
    database.execute('INSERT INTO tag_purpose (name) VALUES (?)', tag_purpose_name)
  end

  # Kolla om användaren existerar
  def database_does_user_exist?(username)
    !database.execute('SELECT username FROM user where user.username = ?', username).empty?
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
    elsif database_does_user_exist?(username)
      'Username taken, choose another username'
    elsif password.empty?
      'You need to type a password'
    elsif password.length < 8
      'Your password needs to be at least 8 characters long'
    elsif password !~ /[A-Z]/
      'Your password needs a capital letter'
    elsif password !~ /[0-9]/
      'Your password needs a number'
    elsif password !~ /[#?!@$ %^&*-]/
      'Your password needs at least one special character: #?!@$%^&*-'
    elsif password != repeat_password
      'Your password\'s don\'t match'
    else
      # No error occured. Register the user
      password_digest = BCrypt::Password.create(password)

      # Add the user to the database
      database.execute('INSERT INTO user (username, digest, permission_level) VALUES (?, ?, ?)', username,
                       password_digest, 'user')

      nil
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

    user = database.execute('SELECT digest, id FROM user WHERE username = ?', username).first

    # Username not found
    return nil if user.nil?

    password_digest = user['digest']

    # Wrong password
    return nil if BCrypt::Password.new(password_digest) != password

    user['id'].to_i
  end
end
