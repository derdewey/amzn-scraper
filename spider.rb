#!/usr/bin/env ruby -Xprofiler.full_report
raise ArgumentError, "Must provide config file!" if ARGV.empty?

require 'rubygems'
require 'yaml'
require 'bundler'
Bundler.require

require 'logger'
require 'mechanize'
# require 'hiredis'
require 'digest/sha1'
# require 'json'

require 'spider/worker'
require 'spider/pool'
require 'amazon/extractors/review'

require 'amazon/tasks/extract_links'
require 'amazon/tasks/extract_reviews'
require 'amazon/tasks/extract_asin'

require 'rubinius/debugger'

LOG = Logger.new(STDOUT)
LOG.level = Logger::INFO

LOG.info "Creating spider pool"
POOL = Spider::Pool.new(:logger => LOG)

LOG.info "Loading config.yaml"
config = YAML.load(File.read("config.yaml"))

LOG.info "Crawling the webs with #{config[:workers]} worker(s)"
config[:workers].to_i.times do |num|
  POOL << Mechanize.new do |agent|
    agent.user_agent_alias = 'Mac Safari'
    agent.redis = Redis.new(config[:redis])
    agent.redis_config = config[:amazon][:redis]
    # agent.log = LOG
    agent.init_state_mutex
    agent.init_tasks
    # Return nil of no values was returned. Will be invoked again by worker, don't worry.
    agent.next = Proc.new do |agnt,rds,cfg|
      redisval = rds.blpop(cfg[:asin][:unvisited], 1)
      page = if(redisval.nil?)
        # We are using a blocking pop. It could return nil if there's nothing in the list. Totally cool.
        nil
      elsif(agnt.redis.sismember(agnt.redis_config[:asin][:visited],redisval))
        agnt.redis.sadd(cfg[:asin][:visited],redisval)
        nil
      else
        asin = redisval[1]
        LOG.info "#{agnt.object_id} getting ASIN #{asin}"
        agnt.get("http://amazon.com/gp/product/"+asin)
      end
      page
    end
    # Worker has no idea what queues or patterns you want. Do that here.
    agent.push = Proc.new do |uri|
      if uri.respond_to?(:request_uri)
        link = uri.request_uri
      elsif uri.respond_to?(:href)
        link = uri.href
      elsif uri.kind_of?(URI::Generic)
        link = uri.to_s
      else
        LOG.error "got an unusable entity #{uri.class}:#{uri} to_s:#{uri.to_s}"
        return
      end
    end
    # agent << Proc.new{|agent,page| Spider::Task::Links.extract(agent,page)}
    # agent << Proc.new{|agent,page| LOG.info "#"*20 + "PROCESSING!" + "#"*20; LOG.info page.reviews.inspect if page.review_page?}
    agent << Proc.new do |agnt, pg|
      LOG.debug "worker##{agnt.object_id} got a page for URL extraction!"
      list = Spider::Task::Links.extract(agnt,pg)
    end
    agent << Proc.new do |agnt, pg|
      LOG.debug "worker##{agnt.object_id} got a page for ASIN extraction!"
      list = Spider::Task::ASIN.extract(agnt,pg)
      # list.each{|asin| LOG.info "ASIN: #{asin}"}
      list.each do |x|
        unless agnt.redis.sismember(agnt.redis_config[:asin][:visited],x)
          agnt.redis.lpush(agnt.redis_config[:asin][:unvisited],x)
        end
      end
    end
    agent << Proc.new do |agnt,pg|
      LOG.debug "worker##{agnt.object_id} going to try siphoning out the reviews"
      LOG.info "Title: " + pg.title
      LOG.info pg.reviews.inspect
    end
  end
end

POOL.start
POOL.join