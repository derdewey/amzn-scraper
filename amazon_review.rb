module Review
  module Amazon
    EXTRACTION_LOOKUP =
      {
       :star_rating           => [[:css, "a + br + div > div + div > span > span > span"],[:text]],
       :name                  => [[:css, "a + br + div > div + div + div > div > div + div > a > span"],[:text]],
       :verified_purchase     => [[:css, "a + br + div > div + div + div > span > b"],[:text]],
       :cross_referenced_from => [[:css, "a + br + div > div + div + div + div + div > b"]],
       :review_body           => [[:css, "a + br + div > div + div + div + div + div"]]
      }.freeze
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
      return EXTRACTION_LOOKUP
    end
    def extract(command_stack)
      @mech.log.info "Extract called with command stack #{command_stack}"
      retval = parser
      step = 0
      command_stack.each do |params|
        @mech.log.debug "Extract step #{step} #{params} being sent to a '#{retval.class}' (hint: '#{retval.to_s[0..25]}')"
        retval = retval.send(*params)
        @mech.log.debug "Extract step #{step} transformed retval to a '#{retval.class}' (hint: '#{retval.to_s[0..25]}')"
        step = step + 1
      end
      @mech.log.debug "Extract returning #{retval}"
      return retval
    end
    def extract_review
      raise "HI!"
    end
  end
end

class Mechanize::Page
  include Review::Amazon
end