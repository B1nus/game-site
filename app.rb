require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'

get('/') do
    redirect('/browse')
end

get('/browse') do
    slim(:browse)
end