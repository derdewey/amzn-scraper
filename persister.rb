#!/usr/bin/env ruby
require 'rubygems'
require 'bundler'
Bundler.require
require 'logger'

config = YAML.load(File.read("config.yaml"))
logger_config = config[:logger]
LOG = if(logger_config[:output] == 'stdout')
  Logger.new(STDOUT)
elsif(logger_config[:output] == 'file')
  Logger.new(File.open('persister.log','a+'))
else
  raise ArgumentError, "not sure how to interpret logger's output of #{logger_config[:ouput]}. Expected stdout or file"
end

LOG.level = if(logger_config[:level] == 'fatal')
  Logger::FATAL
elsif(logger_config[:level] == 'error')
  Logger::ERROR
elsif(logger_config[:level] == 'warn')
  Logger::WARN
elsif(logger_config[:level] == 'info')
  Logger::INFO
elsif(logger_config[:level] == 'debug')
  Logger::DEBUG
else
  raise ArgumentError, "not sure how to interpret logger's level of #{logger_config[:level]}. Expected one of error, warn, info, or debug"
end

REDIS = Redis.new(config[:redis])
DB = Sequel.connect(config[:database])

DB.create_table :reviews do
  varchar :asin,           :limit => 20
  varchar :user_id,        :limit => 20
  varchar :cross_referenced_from
  varchar :name
  boolean :real_name
  boolean :verified_purchase
  float   :star_rating
  varchar :date, :limit => 20
  text    :review_title
  text    :review_body
end unless DB.table_exists?(:reviews)

redis_config = config[:amazon][:redis]

running = true

Signal.trap("INT") do
  running = false
  LOG.fatal "Persister has been requested to stop"
end

while(running)
  review_set_json = REDIS.lpop(redis_config[:reviews][:intransit])
  if(review_set_json.nil?)
    begin
      sleep(5)
    rescue
      running = false # if you're sleeping and an int arrives... does the trap block get executed?
    end
  else
    begin
      review_set = JSON.parse(review_set_json)
      asin = review_set.keys.first
      reviews = review_set[asin]
      db_friendly_reviews = reviews.each do |review|
        review.merge!(:asin => asin)
      end
      LOG.info "Committing for #{asin}"
      DB.transaction do
        DB[:reviews].insert_multiple(db_friendly_reviews)
      end
    rescue => e
      LOG.error "#{ e.message } - (#{ e.class })"
      LOG.fatal review_set_json
    end
  end
end
LOG.fatal "Persister stopped normally"
