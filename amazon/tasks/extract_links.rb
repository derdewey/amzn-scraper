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
      end
    end
  end
end