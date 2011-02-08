module Spider
  module Task
    module Links
      def self.extract(agent,page)
        page.links.each do |l|
          begin
            uri = l.uri
            original_host = agent.history.first.uri.host
          rescue
            next
          end

          next if uri.nil?

          begin
            if (uri.host.nil? || (uri.host == original_host))
              # clean_link = l.uri.gsub!(/(\%0A|\%02)/,'')
              agent.push_link(uri)
            end
          rescue => e
            LOG.error e.backtrace.join("\n")
          end
        end
      end
    end
  end
end