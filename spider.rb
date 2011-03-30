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
# LOG = Logger.new(File.open('run.log','a+'))
LOG.level = Logger::INFO

config = YAML.load(File.read("config.yaml"))

worker_pool = Spider::Pool.new(:logger => LOG)

config[:workers].to_i.times do |num|
  worker_pool << Mechanize.new do |agent|
    agent.user_agent_alias = 'Mac Safari'
    begin
	agent.redis = Redis.new(config[:redis])
    rescue => e
    	LOG.fatal "Could not initialize redis connection. Is server up? Is your config correct?"
    	exit(1)
    end
    agent.redis_config = config[:amazon][:redis]
    agent.log = LOG
    agent.init_state_mutex
    agent.init_tasks
    
    agent.next = Proc.new do |agnt,rds,cfg|
      redisval = rds.spop(cfg[:asin][:unvisited])
      unless (redisval.nil?)
        asin = redisval
        rds.sadd(agnt.redis_config[:asin][:visited],asin)
        
        pages = []
        url_base = "http://www.amazon.com/gp/product-reviews/" + asin + "/?pageNumber="
        begin
          working_url = url_base + (pages.length+1).to_s
          LOG.fatal "Current working URL: " + working_url
          page = agnt.get(working_url)
          rds.sadd(agnt.redis_config[:href][:visited],url_base)
          if(page.title =~ /Kindle/)
            LOG.debug "Blacklisted title: #{page.title}"
            break            
          end
          pages << page
          if(pages.length > 4000)
            LOG.fatal "Base url #{base_url} is leading a worker past 4000 review pages. Breaking out of loop."
            break
          end
        rescue => e
          pages << nil
          break
        end while !pages.last.nil? && pages.last.reviews.length > 2
        {:asin => asin, :pages => pages}
      else
        sleep(5)
        {:asin => nil, :pages => []}
      end
    end
    
    # ASIN extraction
    agent << Proc.new do |agnt, data|
      pgs = data[:pages]
      list = pgs.collect{|pg| Spider::Task::ASIN.extract(agnt,pg)}.flatten
      list.each do |x|
        unless agnt.redis.sismember(agnt.redis_config[:asin][:visited],x)
          agnt.redis.sadd(agnt.redis_config[:asin][:unvisited],x)
        end
      end
    end
    # Review extraction
    agent << Proc.new do |agnt, data|
      asin = data[:asin]
      pgs = data[:pages]
      unless (asin.nil? || pgs.nil? || pgs.empty?)
        reviews = pgs.inject([]) do |arr,pg|
          if(arr.size == 0)
            LOG.fatal pg.product_info
          end
          arr << pg.reviews
        end.flatten
        if(!reviews.nil? && !reviews.empty?)
          outgoing = {asin => reviews}.to_json
          LOG.info outgoing.inspect
          agnt.redis.lpush(agnt.redis_config[:reviews][:intransit],outgoing)
        end
      end
    end
  end
end

config[:workers].to_i.times do |num|
  worker_pool << Mechanize.new do |agent|
    agent.user_agent_alias = 'Mac Safari'
    agent.redis = Redis.new(config[:redis])
    agent.redis_config = config[:amazon][:redis]
    # agent.log = LOG
    agent.init_state_mutex
    agent.init_tasks
    # Return nil of no values was returned. Will be invoked again by worker, don't worry.
    agent.next = Proc.new do |agnt,rds,cfg|
      begin
        unvisited_count = agnt.redis.scard(agnt.redis_config[:href][:unvisited]) || 0
      rescue => e
        LOG.fatal agnt.redis_config[:href][:unvisited].to_s
        raise e
      end
      while(unvisited_count > agnt.redis_config[:href][:high_water_mark])
        sleep(5)
      end
      redisval = rds.spop(cfg[:href][:unvisited])
      # We are using a blocking pop. It could return nil if there's nothing in the list. Totally cool.
      page = if(redisval.nil?)
        sleep(5)
        nil
      elsif(agnt.redis.sismember(agnt.redis_config[:href][:visited],redisval))
        nil
      else
        href = redisval
        LOG.fatal "#{agnt.object_id} getting HREF #{href}"
        agnt.redis.sadd(agnt.redis_config[:href][:visited],redisval)
        begin
          agnt.get(href)
        rescue => e
          LOG.error "#{ e.message } - (#{ e.class })" unless LOG.nil?
          LOG.error "redisval: #{redisval.inspect}"
          (e.backtrace or []).each{|x| LOG.error "\t\t" + x}
          nil
        end
      end
      page
    end
    
    # ASIN extraction
    agent << Proc.new do |agnt, pg|
      list = Spider::Task::ASIN.extract(agnt,pg)
      list.each do |x|
        unless agnt.redis.sismember(agnt.redis_config[:asin][:visited],x)
          agnt.redis.sadd(agnt.redis_config[:asin][:unvisited],x)
        end
      end
    end    
    # Link extraction
    agent << Proc.new do |agnt, pg|
      list = Spider::Task::Links.extract(agnt,pg)
      LOG.debug list.inspect
      list.each do |link|
        unless agnt.redis.sismember(agnt.redis_config[:href][:visited],link)
          agnt.redis.sadd(agnt.redis_config[:href][:unvisited],link)
        end
      end
    end
  end
end

worker_pool.start

Signal.trap("INT") do
  LOG.info "Please wait while #{worker_pool.size} workers are shut down"
  worker_pool.stop
end

worker_pool.join
