module Spider
  module Worker
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
      LOG.debug "push_link link.href #{link.href.inspect}"
      digest = self.href_digest(link.href)
      if(@redis.sismember(VGP_H,digest))
        false
      else
        @redis.sadd(UGP,link.href)
      end
    end
    def pop_link
      link = @redis.spop(UGP)
      LOG.debug "pop_link link: #{link}"
      digest = self.href_digest(link)
      @redis.sadd(VGP_H,digest)
      return link
    end
    def notify_review_parsers
      puts "Notifying review parsers... NOT"
    end
    def seed
      @log.debug "Seeding link list"
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
        LOG.debug "Broke out of while loop in worker thread"
      end
    end
    def join
      @t.join
    end
  end
end
class Mechanize
  include Spider::Worker
end