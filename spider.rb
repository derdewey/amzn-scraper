#!/usr/bin/env ruby
raise ArgumentError, "Must provide config file!" if ARGV.empty?

require 'rubygems'
require 'yaml'
require 'bundler'
Bundler.require

require 'logger'
require 'mechanize'
require 'redis'
require 'digest/sha1'
# require 'json'

require 'spider/worker'
require 'spider/pool'
require 'amazon/extractors/review'

require 'amazon/tasks/extract_hrefs'
require 'amazon/tasks/extract_reviews'
require 'amazon/tasks/extract_asin'

require 'rubinius/debugger'

LOG = Logger.new(STDOUT)
LOG.level = Logger::DEBUG

LOG.info "Creating spider pool"
POOL = Spider::Pool.new(:logger => LOG)

LOG.info "Loading config.yaml"
config = YAML.load(File.read("config.yaml"))

LOG.info "Crawling the webs with #{config[:workers]} worker(s)"
config[:workers][:urls].to_i.times do |num|
  POOL << Mechanize.new do |agent|
    agent.user_agent_alias = 'Mac Safari'
    agent.redis = Redis.new(config[:redis])
    agent.redis_config = config[:amazon][:redis]
    agent.log = LOG
    agent.init_state_mutex
    agent.init_tasks
    # agent << Proc.new{|agent,page| Spider::Task::Links.extract(agent,page)}
    # agent << Proc.new{|agent,page| LOG.info "#"*20 + "PROCESSING!" + "#"*20; LOG.info page.reviews.inspect if page.review_page?}
    agent << Proc.new{|agent, page| Spider::Task::ASIN.extract(agent,page)}
  end
end

config[:workers][:asins].to_i.times do |num|
  
end

seeder = POOL[0]
seeder.seed(config[:amazon][:seed])

Signal.trap("INT") do 
  LOG.fatal "Please wait while #{POOL.spiders.length} spiders are shut down"
  POOL.stop
  @alive = true
end
POOL.start

Thread.new do
  while(@alive ||= true) do
    sleep(1)
    # LOG.info "Pool alive: #{POOL.alive?}"
  end
end.join
