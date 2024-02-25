require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require "./model"

# Länk för att komma in på hemsidan snabbt (:
p "http://localhost:4567/"

# Återkoppla användaren till browse sidan som fungerar som index sida
get('/') do
    redirect('/games')
end

# Visa sidan där man kan söka efter spel
get('/games') do
    @games = database_games() # Alla attribut från alla spel är publika!!!

    @games.each do |game|
        # Kolla efter en tag som varnar för tredjeparts hemsida
        if database_game_tag_purposes(game["id"]).include?({"name"=>"warn_for_foreign"})
            game["url"] = "/warning/#{game["id"]}"
        else
            game["url"] = "/games/#{game["id"]}"
        end
    end

    slim(:"games/index")
end

# Spela ett spel
get('/games/:game_id') do
    @game = database_game_with_id(params[:game_id]) # Alla attribut från alla spel är publika!!!

    slim(:"games/show")
end

# Varning för att jag inte äger spelet
get('/warning/:game_id') do
    game = database_game_with_id(params[:game_id])

    @foreign_url = game["foreign_url"]
    @indigenous_url = "/games/" + game["id"].to_s

    slim(:"warning")
end

# Formulär för att lägga till en ny tag. ADMIN
get "/tags/new" do 
    # ONLY AS ADMIN

    # För att se vad tag purpose id:n står för
    @tag_purposes = database_tag_purposes()

    slim(:"tags/new")
end

# Add a new tag. ADMIN
post "/tags" do
    # ONLY AS ADMIN
    tag_name = params[:tag_name]
    tag_purpose_id = params[:tag_purpose_id]

    database_create_tag(tag_name, tag_purpose_id)

    redirect "/tags"
end

# Formulär för att ändra en tag. ADMIN
get "/tags/:id/edit" do
    # ONLY AS ADMIN
    @tag_id = params[:id]

    tag = database_tag_with_id(@tag_id)

    # För att placera föregående värden
    @tag_name = tag["name"]
    @tag_purpose_id = tag["tag_purpose_id"]

    # För att se vad tag purpose id:n står för
    @tag_purposes = database_tag_purposes()

    slim(:"tags/edit")
end

# Ändra en tag. ADMIN
post "/tags/:id/update" do
    # ONLY AS ADMIN
    tag_id = params[:id]
    tag_name = params[:tag_name]
    tag_purpose_id = params[:tag_purpose_id]

    database_edit_tag(tag_id, tag_name, tag_purpose_id)

    redirect "/tags"
end

# Display all tags. ADMIN
get "/tags" do
    @tags = database_tags()

    slim(:"tags/index")
end

# Visa en tag. (FÅR INTE VARA FÖRE ROUTEN /tags/new!!!)
get "/tags/:id" do
    @tag = database_tag_with_id(params[:id])
    
    slim(:"tags/show")
end

# Ta bort en tag. ADMIN
post "/tags/:id/delete" do
    tag_id = params[:id]

    delete_tag(tag_id)
    
    redirect "/tags"
end

# Restful routes viktigt? Strunta i det för likes, men gör det för tags och spel
# Domän check i app.rb.
# Ta bort länken till scratch see inside. Gör så det är till servern istället
# Restful routes för användare? Är inte /register bättre än /users/new?