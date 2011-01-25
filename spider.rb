#!/usr/bin/env ruby
require 'rubygems'
require 'logger'
require 'bundler'
Bundler.require
require 'mechanize'
require 'redis'
require 'digest/sha1'
require 'json'

LOG = Logger.new(STDOUT)
LOG.level = Logger::ERROR

LOG.info "Initializing key references"
HOST = "www.amazon.com".freeze
# Visited Product Reviews
VPR_H = "reviews:visited:hashes".freeze
# Unvisited
UPR = "reviews:unvisited:hrefs".freeze
# Unvisited general pages
UGP = "pages:unvisited:hrefs".freeze
# Visited general pages hashes
VGP_H = "pages:visited:hashes".freeze

FAKE_NODE = {}
def FAKE_NODE.inner_text
  "dummy text"
end

class SpiderPool
  attr_writer :logger
  def initialize
    @spiders = []
    @logger = nil
    
    yield self if block_given?
  end
  def <<(spider)
    @logger.info "Adding spider" if @logger
    @spiders << spider
  end
  def stop
    @logger.info "Stopping all spiders" if @logger
    @spiders.each{|s| s.stop}
  end
  def start
    @logger.info "Starting all spiders" if @logger
    @spiders.each{|s| s.start}
    @spiders.each{|s| s.join}
    @logger.info "All spiders have stopped" if @logger
  end
end

LOG.info "Initializing spider agent"
class Mechanize
  def init_state_mutex
    @state_muteux = Mutex.new
  end
  def redis=(incoming)
    @redis = incoming
  end
  def redis
    @redis
  end
  def href_digest(link)
    Digest::SHA1.hexdigest(link)
  end
  def push_link(link)
    LOG.info "push_link link.href #{link.href.inspect}"
    digest = self.href_digest(link.href)
    if(@redis.sismember(VGP_H,digest))
      false
    else
      @redis.sadd(UGP,link.href)
    end
  end
  def pop_link
    link = @redis.spop(UGP)
    LOG.info "pop_link link: #{link}"
    digest = self.href_digest(link)
    @redis.sadd(VGP_H,digest)
    return link
  end
  def notify_review_parsers
    puts "Notifying review parsers... NOT"
  end
  def seed
    @log.info "Seeding link list"
    directory = %Q{http://www.amazon.com/Subjects-Books/b/ref=sv_b_1?ie=UTF8&node=1000}
    a.get(directory) do |page|
      page.links.each do |link|
        # LOG.info "Seed stage: #{link.inspect}"
        next if link.uri.nil?
        if(link.uri.host.nil? || link.uri.host =~ /amazon/ || (link.uri.host == a.history.first.uri.host))
          a.push_link link
        end
      end
    end
  end
  def start
    @state = :working
    work
  end
  def stop
    @state = :stopped
  end
  def working?
    @state == :working
  end
  def work
    LOG.info "Starting up a worker thread"
    @t = Thread.new do
      while self.working? && link = pop_link
        LOG.info "Working on #{link.inspect}"
        begin
          page = self.get(link)
          page.links.each do |l|
            next if l.uri.nil?
            if (l.uri.host.nil? || (l.uri.host == self.history.first.uri.host))
              self.push_link(l)
            end
          end
        rescue => e
          LOG.error "#{e.to_s} raised on #{link}. Skipping."
          next
        end
      end
      LOG.info "Broke out of while loop in worker thread"
    end
  end
  def join
    @t.join
  end
end
LOG.info "Creating spider pool"
POOL = SpiderPool.new do |pool|
  pool.logger = LOG
end
5.times do
  POOL << Mechanize.new do |agent|
    agent.user_agent_alias = 'Mac Safari'
    agent.redis = Redis.new(:host => "localhost", :port => 6379, :thread_safe => true)
    agent.log = LOG
    agent.init_state_mutex
  end
end

Signal.trap("INT") do 
  puts "got an INT"
  POOL.stop
end
POOL.start