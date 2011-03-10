module Spider
  module Worker
    NOT_FOUND = "404".freeze
    NEED_ABSOLUTE_URL = "need absolute URL".freeze
    def init_state_mutex
      @state_muteux = Mutex.new
    end
    def init_tasks
      @tasks = []
    end
    def <<(task)
      @tasks << task
    end
    def redis=(incoming)
      @redis = incoming
    end
    def redis
      @redis
    end
    def redis_config=(incoming)
      @redis_config = incoming
    end
    def redis_config
      @redis_config
    end
    def href_digest(link)
      LOG.debug link
      Digest::SHA1.hexdigest(link)
    end
    def empty?
      @redis.llen(@redis_config[:pages][:unvisited]) == 0
    end
    
    # Must provide a string
    def push_link(uri)
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
      
      LOG.debug "push_link link.href #{link.class} #{link}"
      digest = self.href_digest(link)
      if(@redis.sismember(@redis_config[:pages][:visited],digest))
        false
      else
        @redis.lpush(@redis_config[:pages][:unvisited],link)
      end
    end
    def pop_link
      link = @redis.lpop(@redis_config[:pages][:unvisited])
      LOG.debug "pop_link link: #{link}"
      digest = self.href_digest(link)
      @redis.sadd(@redis_config[:pages][:visited],digest)
      return link
    end
    def notify_review_parsers
      puts "Notifying review parsers... NOT"
    end
    def seed(url)
      LOG.info "Seeding link list"
      directory = url
      self.get(directory) do |page|
        page.links.each do |link|
          # LOG.info "Seed stage: #{link.inspect}"
          next if link.uri.nil?
          if(link.uri.host.nil? || link.uri.host =~ /amazon/ || (link.uri.host == self.history.first.uri.host))
            self.push_link link
          end
        end
      end
    end
    def start
      @state = :working
      @t = Thread.new do
        while(self.working? && link = pop_link) do
          work(link)
        end
      end
    end
    def stop
      @state = :stopped
    end
    def working?
      @state == :working
    end
    def join
      @t.join
    end
    def work(link)
      begin
        page = self.get(link)
      rescue Mechanize::ResponseCodeError => e
        if(e.response_code == NOT_FOUND)
          new_link = config[:base] + link.to_s
          LOG.error "Looks like a NOT_FOUND error! Pushing #{new_link}"
          # Worth a try later...
          self.push_link(new_link)
        end
          LOG.error "#{e.class}:#{e}, #{e.response_code.class}:#{e.response_code} raised for #{link}"
        next
      rescue RuntimeError => e
        if(e.to_s.eql?(NEED_ABSOLUTE_URL))
          page = self.get(config[:base] + link)
        else
          LOG.error "#{e.class}:#{e} for #{link}. Not handling!"
          next
        end
      rescue => e
        LOG.error "Unhandled exception #{e.class}:#{e}"
        return
      end
      
      @tasks.each do |task|
        begin
          task.call(self,page)
        rescue => e
          LOG.error "self: #{self.class}:#{self}, page: #{page.class},#{page} #{e.backtrace}"
        end
      end
    end
  end
end
class Mechanize
  include Spider::Worker
end