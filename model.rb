require "sqlite3"
require "sinatra/reloader"

module Model

  def connect_to_database(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
  end

  def connect_to_default_database
    return connect_to_database("data/db.db")
  end

  def database_games
    db = connect_to_default_database

    return db.execute("SELECT * FROM game")
  end

  def database_game_with_id(game_id)
    db = connect_to_default_database

    return db.execute("SELECT * FROM game WHERE id = ?", game_id).first
  end

  def database_game_iframe_size(game_id)
    db = connect_to_default_database

    return db
      .execute(
        "SELECT tag.name as tag_name
    FROM game_tag_rel
    INNER JOIN tag ON tag.id = tag_id
    INNER JOIN tag_purpose ON tag_purpose_id = tag_purpose.id
    WHERE game_id = ? AND tag_purpose.name = \"iframe_size\"",
        game_id
      )
      .map { |e| e = e["tag_name"] }
  end

  def database_game_applied_tags(game_id)
    db = connect_to_default_database

    return db.execute(
      "SELECT tag.id as tag_id, tag.name as tag_name, tag.tag_purpose_id, tag_purpose.name as tag_purpose_name FROM game_tag_rel
    RIGHT JOIN tag ON game_tag_rel.tag_id = tag.id
    LEFT JOIN tag_purpose ON tag_purpose.id = tag_purpose_id
    WHERE game_id = ?",
      game_id
    )
  end

  def database_game_available_tags(game_id)
    db = connect_to_default_database

    return db.execute(
      "SELECT t.id as tag_id, t.name as tag_name, tag_purpose_id, tag_purpose.name as tag_purpose_name
    FROM tag t
    LEFT JOIN game_tag_rel gtr ON t.id = gtr.tag_id AND gtr.game_id = ?
    LEFT JOIN tag_purpose ON tag_purpose.id = tag_purpose_id
    WHERE gtr.game_id IS NULL;",
      game_id
    )
  end

  def database_game_tag_purposes(game_id)
    db = connect_to_default_database

    return db.execute(
      "SELECT tag_purpose.name FROM game_tag_rel
    INNER JOIN tag ON game_tag_rel.tag_id = tag.id
    INNER JOIN tag_purpose ON tag.tag_purpose_id = tag_purpose.id
    WHERE game_id = ?",
      game_id
    )
  end

  def database_tags
    db = connect_to_default_database

    return db.execute(
      "SELECT tag.id as tag_id, tag.name as tag_name, tag.tag_purpose_id, tag_purpose.name as tag_purpose_name FROM tag
    LEFT JOIN tag_purpose ON tag_purpose.id = tag.tag_purpose_id"
    )
  end

  def database_tag_with_id(tag_id)
    db = connect_to_default_database

    return db
      .execute(
        "SELECT tag.id as id, tag.name as tag_name, tag_purpose_id, tag_purpose.name as tag_purpose_name FROM tag
    LEFT JOIN tag_purpose ON tag_purpose.id = tag.tag_purpose_id
    WHERE tag.id = ?",
        tag_id
      )
      .first
  end

  def database_create_tag(tag_name, tag_purpose_id)
    db = connect_to_default_database

    db.execute("INSERT INTO tag (name, tag_purpose_id) VALUES (?, ?)", tag_name, tag_purpose_id)
  end

  def database_edit_tag(tag_id, tag_name, tag_purpose_id)
    db = connect_to_default_database

    db.execute(
      "UPDATE tag 
    SET name = ?, tag_purpose_id = ? 
    WHERE id = ?",
      tag_name,
      tag_purpose_id,
      tag_id
    )
  end

  def delete_tag(tag_id)
    db = connect_to_default_database

    db.execute("DELETE FROM tag WHERE id = ?", tag_id)
  end

  # Lista över alla tag syften
  def database_tag_purposes
    db = connect_to_default_database

    return db.execute("SELECT * FROM tag_purpose")
  end

  # Lägg till ett tag syfte
  def database_create_tag_purpose(tag_purpose_name)
    db = connect_to_default_database

    db.execute("INSERT INTO tag_purpose (name) VALUES (?)", tag_purpose_name)
  end

  # Kolla om användaren existerar
  def database_does_user_exist?(username)
    db = connect_to_default_database

    count = db.execute("SELECT count(username) FROM user where user.username = ?", username).first["count(username)"]

    return count >= 1
  end

end

# CRUD på tag purposes
# lägg in /tag_purpose/index.slim i edit och new av tags (så man kan se vad tag_purpose id står för)
