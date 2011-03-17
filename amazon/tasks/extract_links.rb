module Spider
  module Task
    module Links
      def self.extract(agent,page)
        retval = []
        page.links.each do |l|
          begin
            uri = l.uri
            original_host = agent.history.first.uri.host
          rescue
            next
          end

          next if uri.nil?

          begin
            if ((uri.host.nil? || (uri.host == original_host)) && (uri.to_s !~ /javascript/))
              retval << uri
            end
          rescue => e
            LOG.error e.backtrace.join("\n")
          end
        end
        retval.uniq!
        retval = retval.collect do |x|
          if(x.host =~ /amazon/)
            x.to_s
          elsif(x.host.nil?)
            "http://www.amazon.com" + x.to_s
          else
            nil
          end
        end
        retval = retval.select do |x|
          !x.nil?
        end
        retval.uniq!
        
        return retval
      end
    end
  end
end