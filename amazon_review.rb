module Review
  module Amazon
    def is_review?
      
    end
  end
end

class Mechanize::Page
  include Review::Amazon
end