module Spider
  module Worker
    NOT_FOUND = "404".freeze
    NEED_ABSOLUTE_URL = "need absolute URL".freeze
    AMAZON_BASE_URL = "http://www.amazon.com".freeze
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
    def href_digest(link)
      LOG.debug link
      Digest::SHA1.hexdigest(link)
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
      if(@redis.sismember(VGP_H,digest))
        false
      else
        @redis.lpush(UGP,link)
      end
    end
    def pop_link
      link = @redis.lpop(UGP)
      LOG.debug "pop_link link: #{link}"
      digest = self.href_digest(link)
      @redis.sadd(VGP_H,digest)
      return link
    end
    def notify_review_parsers
      puts "Notifying review parsers... NOT"
    end
    def seed
      LOG.debug "Seeding link list"
      directory = %Q{http://www.amazon.com/Subjects-Books/b/ref=sv_b_1?ie=UTF8&node=1000}
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
          rescue Mechanize::ResponseCodeError => e
            if(e.response_code == NOT_FOUND)
              new_link = "http://www.amazon.com/" + link.to_s
              LOG.error "Looks like a NOT_FOUND error! Pushing #{new_link}"
              # Worth a try later...
              self.push_link(new_link)
            end
              LOG.error "#{e.class}:#{e}, #{e.response_code.class}:#{e.response_code} raised for #{link}"
            next
          rescue RuntimeError => e
            if(e.to_s.eql?(NEED_ABSOLUTE_URL))
              page = self.get(AMAZON_BASE_URL + link)
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
    def list_is_empty?
      return false unless @redis.exists(UGP)
      @redis.llen(UGP).eql?(0)
    end
    def join
      @t.join
    end
  end
end
class Mechanize
  include Spider::Worker
end