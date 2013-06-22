require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'debugger'
require 'mongoid'
require 'json'

set :public_folder, Proc.new { File.join(root, "static") }

configure do
  Mongoid.load! 'mongoid.yaml'
end

helpers do
end

before do
  content_type 'application/json'
end

class Product
  include Mongoid::Document
  field :product_code, type: Integer
  field :name, type: String 
  field :description, type: String  
  field :price, type: Integer
  field :tags, type: Array

end

class Review
  include Mongoid::Document
  field :title, type: String
  field :text, type: String
  field :rating, type: Integer
end

# get '/' do
#   @products = Product.all
#   content_type 'text/html'
#   erb :home
#  end

get '/api/v1/products' do
  @products = Product.all
  Product.all.to_json
end

get '/api/v1/products/:id' do
  # debugger
  product = Product.where(product_code: params[:id])

  halt 404 if product.nil?

  product.to_json
end

post '/api/v1/products' do
  request_data = JSON.parse request.body.read
  # debugger
  unless request_data.nil? || request_data['product_code'].nil? || request_data['name'].nil? || request_data['price'].nil? || request_data['description'].nil? 
  product = Product.new request_data 
else
  halt 400
end


  halt 500 unless product.save
  # debugger

  [201, {'Location' => "/api/v1/products/#{product.product_code}"}, product.to_json]
  #Product.all.to_json
end


put '/api/v1/products/:id' do
  debugger
  data = JSON.parse(request.body.read)
  halt 400 if data.nil?
  debugger
  product = Product.find_by(product_code: params[:id])
  halt 404 if product.nil?

  %w(product_code name description price tags).each do |key|
    if !data[key].nil? && data[key] != product[key]
      product.write_attribute(key, data[key])
    end
  end

  halt 500 unless product.save
  product.to_json
end

delete '/api/v1/products/:id' do
  product = Product.find_by(product_code: params[:id])
  halt 404 if product.nil?

  if product.destroy
    "Product #{product.name} has been pulverized"
  else 
    halt 500
  end  
end

get '/api/v1/reviews' do
  reviews = Review.all
  reviews.to_json
end

post '/api/v1/reviews' do
  request_data = JSON.parse request.body.read
  debugger
  if request_data.nil? && request_data.text.nil? && request_data.rating.nil?
    halt 400
  else
    review = Review.new request_data
  end

  halt 500 unless review.save
end