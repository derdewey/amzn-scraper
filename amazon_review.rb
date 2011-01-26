module Review
  module Amazon
    def is_review?
      # rev is the review div
      # How to get "5.0 out of 5 stars" entry
      rev.css("a + br + div > div + div > span > span > span")
      # How to get "Firstname Lastname" entry
      rev.css("a + br + div > div + div + div > div > div + div > a > span").first.text.strip
    end
  end
end

class Mechanize::Page
  include Review::Amazon
end