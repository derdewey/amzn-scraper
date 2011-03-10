require 'extract_hrefs'

module Amazon
  module Tasks
    module Seed
      def seed(url)
        page = self.get(url)
        extract(self,page)        
      end
    end
  end
end

class Mechanize
  include Amazon::Tasks::Seed
end