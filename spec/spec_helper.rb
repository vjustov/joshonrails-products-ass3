['product', 'review'].each do |file|
  require File.join File.dirname(__FILE__), '..', 'lib/#{file}.rb'
end

require 'json'

Rspec.configure do |config|
  config.color_enabled = true
  config.formatter = :documentation
end