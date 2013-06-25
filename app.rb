require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'debugger' if development?
require 'mongoid'
require 'json'

set :public_folder, Proc.new { File.join(root, "static") }

configure do
  Mongoid.load! 'mongoid.yaml'
end

helpers do
end

before do
  content_type 'text/html' #'application/json'
end

class Product
  include Mongoid::Document
  field :product_code, type: Integer
  field :name, type: String 
  field :description, type: String  
  field :price, type: Integer
  field :tags, type: Array
  field :reviews, type: Array

  embeds_many :reviews

end

class Review
  include Mongoid::Document
  field :title, type: String
  field :text, type: String
  field :rating, type: Integer

  embedded_in :product
end

get '/' do
  @products = Product.all
  content_type 'text/html'
  erb :home
 end

get '/form' do
  content_type 'text/html'
  erb :form
end

get '/form/:id' do
  content_type 'text/html'
  # debugger
  @product = Product.find_by(product_code: params[:id])
  erb :form
end

get '/clean' do
  content_type 'text/html'
  # debugger
  Product.destroy_all()
  Review.destroy_all()
  erb :home
end

get '/destroy/:id' do
  content_type 'text/html'
  # debugger
  @product = Product.find_by(product_code: params[:id])
  erb :product_destroy
end

get '/review_form/:id' do
  content_type 'text/html'
  @product_code = params[:id]
  erb :reviews_form
end

get '/api/v1/products' do
  @products = Product.all
  Product.all.to_json
  erb :home
end

get '/top10' do
  # content_type 'application/json'
  products = Product.all.entries
  # debugger
  avrgs = {}
  products.each do |p| 
    avrgs[p.name] = p.reviews.map { |r| r['rating'].to_i }.reduce(:+).div(p.reviews.size) if p.reviews.size > 0
    # debugger
  end

  @lalala = avrgs.to_json
  erb :average
end

get '/api/v1/products/:id' do
  # debugger
  @product = Product.where(product_code: params[:id]).first

  halt 404 if @product.nil?

  erb :products_show
end

post '/api/v1/products' do
  # debugger

  request_data = unless params.nil? 
      JSON.parse params.to_json
    else 
      JSON.parse request.body.read 
  end

  # debugger
  request_data['product_code'] = Product.all.distinct('product_code').sort.last || 0
  request_data['product_code'] += 1
  request_data['reviews'] = []
  request_data.delete '_method'
  # debugger
  unless request_data.nil? || request_data['product_code'].nil? || request_data['name'].nil? || request_data['price'].nil? || request_data['description'].nil? 
  @product = Product.new request_data 
else
  halt 400
end


  halt 500 unless @product.save
  # debugger

  erb :products_show

  #[201, {'Location' => "/api/v1/products/#{product.product_code}"}, product.to_json]
  #Product.all.to_json
end


put '/api/v1/products/:id' do
  # debugger
  data = unless params.nil? 
      JSON.parse params.to_json
    else 
      JSON.parse request.body.read 
  end
  halt 400 if data.nil?
  # debugger
  @product = Product.find_by(product_code: params[:id])
  halt 404 if @product.nil?

  %w(product_code name description price tags).each do |key|
    if !data[key].nil? && data[key] != @product[key]
      @product.write_attribute(key, data[key])
    end
  end

  halt 500 unless @product.save
  erb :products_show
end

delete '/api/v1/products/:id' do
  product = Product.find_by(product_code: params[:id])
  halt 404 if product.nil?

  if product.destroy
    @error = "Product #{product.name} has been pulverized"
    @products = Product.all
    erb :home
  else 
    halt 500
  end  
end

get '/api/v1/reviews' do
  reviews = Review.all
  # debugger
  reviews.to_json
end

post '/api/v1/reviews/:id' do
  # debugger
  request_data = unless params.nil? 
      JSON.parse params.to_json
    else 
      JSON.parse request.body.read 
  end

  if request_data.nil? && request_data['text'].empty? && request_data['rating'].empty?
    halt 400
  end
  
    @product =  Product.find_by(product_code: params[:id])
    debugger
    request_data.delete 'splat'
    request_data.delete 'id'
    request_data.delete 'captures'
    array  = @product['reviews'] 
    array << request_data
    @product.update_attributes(reviews: array)
    
    #review = Review.new request_data
  
  debugger
  halt 500 unless @product.save

  erb :products_show

  #[201, {'Location' => "/api/v1/products/#{product.product_code}"}, product.to_json]
  #Product.all.to_json


end