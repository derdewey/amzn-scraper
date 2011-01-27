module Review
  module Amazon
    def a_review_page?
      # "5.0 out of 5 stars"
      rev.css("a + br + div > div + div > span > span > span")
      
      # "Firstname Lastname"
      rev.css("a + br + div > div + div + div > div > div + div > a > span").first.text.strip
      
      # OPTIONAL "Amazon Verified Purchase"
      rev.css("a + br + div > div + div + div > span > b")
      
      # OPTIONAL "This review is from..."
      rev.css("a + br + div > div + div + div + div + div > b")
      
      # Review body
      # Not inside of a div but surrounded by them. Must find previous sibling.
       doc.css("a + br + div > div + div + div + div + div").collect{|x| x.next_sibling}.select{|x| x.text.length != 0}.each{|x| puts "'" + x.text.strip.gsub(/\s{2,}/,' ') + "'"}; nil
    end
    def extraction_lookup
      {
       :star_rating           => [[:css, "a + br + div > div + div > span > span > span"]],
       :name                  => [[:css, "a + br + div > div + div + div > div > div + div > a > span"]],
       :verified_purchase     => [[:css, "a + br + div > div + div + div > span > b"]],
       :cross_referenced_from => [[:css, "a + br + div > div + div + div + div + div > b"]],
       :review_body           => [[:css, "a + br + div > div + div + div + div + div"]]
      }
    end
    def extract(command_stack)
      
    end
    def extract_review
      raise "HI!"
    end
  end
end

class Mechanize::Page
  include Review::Amazon
end