require 'mongo'
require 'uri'
require 'json'

def mongo
  return @mongo if @mongo

  # configure connection via ENV['MONGODB_URI']
  # bash:
  #  export MONGODB_URI=mongodb://username:password@host:port/dbname
  # heroku:
  #  heroku config:set MONGODB_URI=mongodb://username:password@host:port/dbname
  client = Mongo::MongoClient.new
  @mongo = client.db
end

def memos
  mongo.collection("memos")
end

before do
  content_type = "application/json"
end

get '/memos' do
  memos.find.to_a.to_json
end

post '/memos' do
  inserted_id = memos.insert(title: params[:title], description: params[:description])
  inserted_id.to_json
end

get '/memos/:id' do
  id = BSON::ObjectId(params[:id])

  docs = memos.find(_id: id).to_a
  halt 404, { message: "not found" }.to_json if docs.none?

  docs[0].to_json
end

put '/memos/:id' do
  id = BSON::ObjectId(params[:id])

  docs = memos.find(_id: id).to_a
  halt 404, { message: "not found" }.to_json if docs.none?

  filter = ["title", "description"]
  update_params = params.select { |key, _| filter.include? key }
  memos.update({ _id: id }, docs[0].merge(update_params))

  updated_docs = memos.find(_id: id).to_a
  halt 500, { message: "failed to update memo" }.to_json if updated_docs.none?

  updated_docs[0].to_json
end

delete '/memos/:id' do
  id = BSON::ObjectId(params[:id])

  memos.remove(_id: id)
  halt 500, { message: "failed to remove memo" }.to_json unless memos.find(_id: id).to_a.none?

  { message: "succeeded to remove memo" }.to_json
end
