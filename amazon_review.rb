module Review
  module Amazon
    REVIEW_EXTRACTION =
      {
       :most_common_node      => [[:css, "a + br + div > div + div > span > span > span"], [:collect, &Proc.new{|x| x.parent_node.parent_node.parent_node.parent_node.parent_node}]],
       :star_rating           => [[:css, "a + br + div > div + div > span > span > span"],[:text]],
       :name                  => [[:css, "a + br + div > div + div + div > div > div + div > a > span"],[:text]],
       :verified_purchase     => [[:css, "a + br + div > div + div + div > span > b"],[:text]],
       :cross_referenced_from => [[:css, "a + br + div > div + div + div + div + div > b > span"],[:first],[:next_sibling],[:text],[:gsub!,/\s{2,}/,' '],[:strip!]],
       :review_body           => [[:css, "a + br + div > div + div + div + div + div"],[:first],[:next_sibling],[:text],[:gsub!,/\s{2,}/,' '],[:strip!]]
      }.freeze
    PRODUCT_EXTRACTION =
    {
      :title                  => [[:css, "body > table > tr > td > h1 + div > h1 + div > h1 > a"],[:text],[:gsub!,/\s{2,}/,' '],[:strip!]],
      :author                 => [[:css, "div.cBoxInner > div.crProductInfo > table > tr > td + td > div.description > a"],[:first],[:next_sibling],[:text],[:strip!],[:gsub!,/by /,'']],
      :price                  => [[:css, "div.cBoxInner > div.crProductInfo > table > tr > td + td > div.buyBlock > div.pricing > span.price"],[:first],[:text]]
    }.freeze
    def a_review_page?
      raise
    end
    def review_extractors
      return REVIEW_EXTRACTION
    end
    def product_extractors
      return PRODUCT_EXTRACTION
    end
    def extract(command_stack, nokogiri_doc = nil)
      @mech.log.debug %Q{Extract called with command stack #{command_stack}}
      if(nokogiri_doc == nil)
        retval = parser
      else
        retval = nokogiri_doc
      end
      
      step = 0
      command_stack.each do |params|
        @mech.log.debug "Extract step #{step} #{params} being sent to a '#{retval.class}' (hint: '#{retval.to_s[0..25]}')"
        retval = retval.send(*params)
        @mech.log.debug "Extract step #{step} transformed retval to a '#{retval.class}' (hint: '#{retval.to_s[0..25]}')"
        step = step + 1
      end
      @mech.log.debug "Extract returning '#{retval}'"
      return retval
    end
    def extract_all_reviews
      reviews = self.extract(REVIEW_EXTRACTION[:most_common_node])
      @mech.log.error "Going through the nodeset #{reviews.class}"
      retval = []
      reviews.inject(retval) do |review,arr|
        @mech.log.debug "Hitting up review #{review.class}:#{review.inspect[0..50]}"
        # review.write_to(STDOUT, :indent => 2)
        raise self.extract(REVIEW_EXTRACTION[:star_rating],review).inspect
      end
    end
  end
end

class Mechanize::Page
  include Review::Amazon
end