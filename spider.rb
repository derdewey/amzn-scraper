#!/usr/bin/env ruby
raise ArgumentError, "Must provide number of worker threads" if ARGV.empty?

require 'rubygems'
require 'bundler'
Bundler.require

require 'logger'
require 'mechanize'
require 'redis'
require 'digest/sha1'
# require 'json'

require 'constants'
require 'spider_worker'
require 'spider_pool'
require 'amazon_review'

require 'tasks/extract_hrefs'

LOG = Logger.new(STDOUT)
LOG.level = Logger::DEBUG

LOG.info "Creating spider pool"
POOL = Spider::Pool.new(:logger => LOG)

LOG.info "Crawling the webs with #{ARGV[0]} worker(s)"
ARGV[0].to_i.times do |num|
  POOL << Mechanize.new do |agent|
    agent.user_agent_alias = 'Mac Safari'
    agent.redis = Redis.new(:host => "localhost", :port => 6379, :thread_safe => true)
    agent.log = LOG
    agent.init_state_mutex
    agent.init_tasks
    agent << Proc.new{|agent,page| Spider::Task::Links.extract(agent,page)}
    agent << Proc.new{|agent,page| LOG.info "#"*20 + "PROCESSING!" + "#"*20; LOG.info page.reviews.inspect if page.review_page?}
  end
end

POOL[0].seed

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
