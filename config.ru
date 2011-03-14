#!/usr/bin/env ruby
require 'logger'
require 'app'
require 'resque/server'

use Rack::ShowExceptions

# Set the AUTH env variable to your basic auth password to protect Resque.
AUTH_PASSWORD = ENV['AUTH']
if AUTH_PASSWORD
  Resque::Server.use Rack::Auth::Basic do |username, password|
    password == AUTH_PASSWORD
  end
end

config = YAML.load(File.read("config.yaml"))
Resque.redis = Redis.new(config[:redis])

run Rack::URLMap.new \
  "/"       => Resque::Server.new