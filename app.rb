require 'rubygems'
require 'bundler/setup'
require 'tilt/erb'
require 'sinatra'

# Configuration

configure do
  set :bind, '0.0.0.0'
end

# Models

QUOTES = Array.new
File.readlines("HAL_quotes.txt").each {|quote| QUOTES.push(quote)}

# Controllers

get '/*' do
  @greeting="Hello world!"
  @quote="\"#{QUOTES.sample.strip}\""
  erb :index
end
