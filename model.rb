require 'sqlite3'
require 'sinatra/reloader'

def connect_to_database(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

def connect_to_default_database()
    return connect_to_database('data/db.db')
end

def database_games()
    db = connect_to_default_database()

    return db.execute("SELECT * FROM game")
end

def database_game_with_id(game_id)
    db = connect_to_default_database()

    return db.execute("SELECT * FROM game WHERE id = ?", game_id).first
end

def database_game_tags(game_id)
    db = connect_to_default_database()

    return db.execute("SELECT tag.id as tag_id, tag.name as tag_name, tag.tag_purpose_id as tag_purpose_id FROM game_tag_rel
    LEFT JOIN tag ON game_tag_rel.tag_id = tag.id
    WHERE game_id = ?", game_id)
end

def database_game_tag_purposes(game_id)
    db = connect_to_default_database()

    return db.execute("SELECT tag_purpose.name FROM game_tag_rel
    INNER JOIN tag ON game_tag_rel.tag_id = tag.id
    INNER JOIN tag_purpose ON tag.tag_purpose_id = tag_purpose.id
    WHERE game_id = ?", game_id)
end

def database_tags()
    db = connect_to_default_database()

    return db.execute("SELECT *, tag.id as id, tag.name as name, tag_purpose.name as tag_purpose_name FROM tag
    LEFT JOIN tag_purpose ON tag_purpose.id = tag.tag_purpose_id")
end

def database_tag_with_id(tag_id)
    db = connect_to_default_database()

    return db.execute("SELECT *, tag.id as id, tag.name as name, tag_purpose.name as tag_purpose_name FROM tag
    LEFT JOIN tag_purpose ON tag_purpose.id = tag.tag_purpose_id
    WHERE tag.id = ?", tag_id).first
end

def database_create_tag(tag_name, tag_purpose_id)
    db = connect_to_default_database()

    db.execute("INSERT INTO tag (name, tag_purpose_id) VALUES (?, ?)", tag_name, tag_purpose_id)
end

def database_edit_tag(tag_id, tag_name, tag_purpose_id)
    db = connect_to_default_database()

    db.execute("UPDATE tag 
    SET name = ?, tag_purpose_id = ? 
    WHERE id = ?", tag_name, tag_purpose_id, tag_id)
end

def delete_tag(tag_id)
    db = connect_to_default_database()

    db.execute("DELETE FROM tag WHERE id = ?", tag_id)
end

def database_tag_purposes()
    db = connect_to_default_database()

    return db.execute("SELECT * FROM tag_purpose")
end

# CRUD på tag purposes
# lägg in /tag_purpose/index.slim i edit och new av tags (så man kan se vad tag_purpose id står för)
