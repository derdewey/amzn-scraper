module Spider
  module Task
    module ASIN
      # ID = %r{(gp/product/|detail/-/)([A-Z0-9^\n]{10})}
      ID = %r{(dp/|gp/product/|detail/-/|ASIN=)([A-Z0-9]{10})}
      def self.extract(agent,page)
        retval = []
        page.links.each do |link|
          next if (link.uri.nil?)
          begin
            if(match = ID.match(link.uri.to_s))
              asin = match[2]
              retval << asin.to_s
            end
          rescue 
            LOG.fatal "Problem with #{link.inspect} with uri #{link.uri}"
            Rubinius::Debugger.start
          end
        end
        retval.uniq!
        return retval
      end
    end
  end
end