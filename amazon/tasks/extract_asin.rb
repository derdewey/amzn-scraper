module Spider
  module Task
    module ASIN
      ID = %r{(gp/product/|detail/-/)([A-Z0-9]{10})}
      def self.extract(agent,page)
        page.links.each do |link|
          next if (link.uri.nil?)
          begin
            if(match = ID.match(link.uri.to_s))
              asin = match[2]
              LOG.debug "Spider::Task::ASIN extracted #{asin}"
              agent.redis.sadd "unvisted:asin", asin
            end
          rescue 
            LOG.error "Problem with #{link.inspect} with uri #{link.uri}"
            Rubinius::Debugger.start
          end
          # begin
          #   if (match = ID.match(uri.href))
          #     LOG.error match.inspect
          #     # agent.redis.lpush(uri)
          #   end
          # rescue => e
          #   LOG.error "Hit error on #{l.inspect}"
          #   LOG.error e.backtrace.join("\n")
          # end
        end
      end
    end
  end
end