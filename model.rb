require 'sqlite3'

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

def database_game_by_id(game_id)
    db = connect_to_default_database()

    return db.execute("SELECT * FROM game WHERE id = ?", game_id).first
end
