module Review
  module Amazon
    REVIEW_EXTRACTION =
      {
       :most_common_node      => [{:params => [:css, "a + br + div > div + div > span > span > span"]},
                                  {:params => [:collect], :block => lambda{|x| x.parent.parent.parent.parent}}],
       :star_rating           => [{:params => [:css, "a + br + div > div + div > span > span > span"]},
                                  {:params => [:first]},
                                  {:params => [:text]}],
       :name                  => [{:params => [:css, "a + br + div > div + div + div > div > div + div > a > span"]},
                                  {:params => [:text]}],
       :verified_purchase     => [{:params => [:css, "a + br + div > div + div + div > span > b"]},
                                  {:params => [:text]}],
       :cross_referenced_from => [{:params => [:css, "a + br + div > div + div + div + div + div > b > span"]},
                                  {:params => [:first]},
                                  {:params => [:next_sibling]},
                                  {:params => [:text]},
                                  {:params => [:gsub,/\s{2,}/,' ']},
                                  {:params => [:strip]}],
       :review_body           => [{:params => [:css, "div + div + div + div + div"]},
                                  {:params => [:inject,nil], :block => lambda{|str,entry| str = Review::Amazon.integrate(str,entry); str}},
                                  {:params => [:gsub,/\s{2,}/,' ']},
                                  {:params => [:strip]}
                                  ],
       :old_review_body           => [{:params => [:css, "a + br + div > div + div + div + div + div"]},
                                  {:params => [:first]},
                                  {:params => [:next_sibling]},
                                  {:params => [:text]},
                                  {:params => [:gsub,/\s{2,}/,' ']},
                                  {:params => [:strip]}]
      }.freeze
    PRODUCT_EXTRACTION =
    {
      :title                  => [{:params => [:css, "body > table > tr > td > h1 + div > h1 + div > h1 > a"]},
                                  {:params => [:text]},
                                  {:params => [:gsub,/\s{2,}/,' ']},
                                  {:params => [:strip]}],
      :author                 => [{:params => [:css, "div.cBoxInner > div.crProductInfo > table > tr > td + td > div.description > a"]},
                                  {:params => [:first]},
                                  {:params => [:next_sibling]},
                                  {:params => [:text]},
                                  {:params => [:strip!]},
                                  {:params => [:gsub,/by /,'']}],
      :price                  => [{:params => [:css, "div.cBoxInner > div.crProductInfo > table > tr > td + td > div.buyBlock > div.pricing > span.price"]},
                                  {:params => [:first]},
                                  {:params => [:text]}]
    }.freeze
    def review_extractors
      return REVIEW_EXTRACTION
    end
    def product_extractors
      return PRODUCT_EXTRACTION
    end
    def extract(command_stack, nokogiri_doc = nil)
      # @mech.log.debug %Q{Extract called with command stack #{command_stack}}
      if(nokogiri_doc == nil)
        retval = parser
      else
        retval = nokogiri_doc
      end
      
      command_stack.each_with_index do |command,index|
        @mech.log.debug "Extract step #{index} #{command.inspect} being sent to a '#{retval.class}' (hint: '#{retval.to_s[0..25]}')"
        if(command[:block])
          retval = retval.send(*command[:params], &command[:block])
        else
          retval = retval.send(*command[:params])
        end
        # @mech.log.debug "Extract step #{index} transformed retval to a '#{retval.class}' (hint: '#{retval.to_s[0..25]}')"
      end
      # @mech.log.debug "Extract returning '#{retval[0..250]}'"
      return retval
    end
    def extract_all_reviews
      reviews = self.extract(REVIEW_EXTRACTION[:most_common_node])
      # @mech.log.error "Going through the nodeset #{reviews.class}"
      # reviews[3].write_to(STDOUT, :indent=> 2)
      # @mech.log.error "WAH"
      # raise self.extract(REVIEW_EXTRACTION[:review_body],reviews[3]).inspect
      # exit(1)
      retval = []
      reviews.inject(retval) do |arr,review|
        begin
          val = self.extract(REVIEW_EXTRACTION[:review_body],review)
        rescue => e
          @mech.log.error "Could not extract because of #{e}. Going to next possible review entity."
          next
        end
        # next if val == "nil"
        raise val.inspect
        # review.write_to(STDOUT, :indent => 2)
        # self.extract(REVIEW_EXTRACTION[:star_rating],review)
        arr
      end
    end
    def self.integrate(str,head)
      if(str.nil?)
        str = ""
      end
      entry = head
      while(entry = entry.next)
        next if entry.kind_of? Nokogiri::XML::Element
        str += entry.text
      end
      return str
    end
  end
end

class Mechanize::Page
  include Review::Amazon
end