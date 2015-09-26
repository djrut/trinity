require 'rubygems'
require 'bundler/setup'
require 'tilt/erb'
require 'sinatra'

configure do
  set :bind, '0.0.0.0'
end

get '/' do
  @greeting="Hello world!"
  erb :index
end
