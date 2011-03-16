module Spider
  module Task
    module ASIN
      # ID = %r{(gp/product/|detail/-/)([A-Z0-9^\n]{10})}
      ID = %r{(dp/|gp/product/|detail/-/|ASIN=)([A-Z0-9]{10})}
      def self.extract(agent,page)
        retval = []
        begin
          page.links.each do |link|
            next if (link.uri.nil?)
            if(match = ID.match(link.uri.to_s))
              asin = match[2]
              retval << asin.to_s
            end
          end
        rescue => e
          LOG.error "#{ e.message } - (#{ e.class })" unless LOG.nil?
          (e.backtrace or []).each{|x| LOG.error "\t\t" + x}
        end
        retval.uniq!
        return retval
      end
    end
  end
end