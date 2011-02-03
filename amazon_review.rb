module Review
  module Amazon
    REVIEW_MOST_COMMON_NODE   =  [{:params => [:css, "a + br + div > div + div > span > span > span".freeze]},
                                  {:params => [:collect], :block => lambda{|x| x.parent.parent.parent.parent}.freeze}]
    REVIEW_EXTRACTION =
      {:star_rating           => [{:params => [:css, "div + div > span > span > span".freeze]},
                                  {:params => [:first]},
                                  {:params => [:text]},
                                  {:params => [:gsub, /\s{2,}/,' ']},
                                  {:params => [:split, ' ']},
                                  {:params => [:at, 0]},
                                  {:params => [:to_f]}],
       :name                  => [{:params => [:css, "div + div + div > div > div + div > a > span".freeze]},
                                  {:params => [:text]},
                                  {:params => [:gsub,/\s{2,}/,' ']}],
       :verified_purchase     => [{:params => [:css, "div + div + div > span > b".freeze]},
                                  {:params => [:text]},
                                  {:params => [:eql?,"Amazon Verified Purchase".freeze]}],
       :cross_referenced_from => [{:params => [:css, "div + div + div + div + div > b > span".freeze]},
                                  {:params => [:first]},
                                  {:params => [:next_sibling]},
                                  {:params => [:text]},
                                  {:params => [:gsub,/\s{2,}/,' ']},
                                  {:params => [:strip]}],
       :review_body           => [{:params => [:css, "div + div + div + div + div"]},
                                  {:params => [:inject,nil], :block => lambda{|str,entry| str = Spider::Helpers.integrate(str,entry); str}.freeze},
                                  {:params => [:gsub,/\s{2,}/,' ']},
                                  {:params => [:strip]}]
      }.freeze
    PRODUCT_EXTRACTION =
      {:title                  => [{:params => [:css, "body > table > tr > td > h1 + div > h1 + div > h1 > a"]},
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
    def execute_command_stack(command_stack, nokogiri_doc = nil)
      # @mech.log.debug %Q{Extract called with command stack #{command_stack}}
      if(nokogiri_doc == nil)
        retval = parser
      else
        retval = nokogiri_doc
      end
      
      command_stack.each_with_index do |command,index|
        @mech.log.debug "Excuting step #{index} #{command.inspect} being sent to a '#{retval.class}' (hint: '#{retval.to_s[0..75]}')"
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
    def review_nodes
      self.execute_command_stack(REVIEW_MOST_COMMON_NODE) rescue []
    end
    def review_page?
      !review_nodes.empty?
    end
    def extract_all_reviews
      review_nodes.inject([]) do |arr,review|
        begin
          val = REVIEW_EXTRACTION.inject({}) do |hash,entry|
            name, command_stack = entry
            hash[name] = self.execute_command_stack(REVIEW_EXTRACTION[name],review)
            hash
          end
        rescue => e
          @mech.log.debug "Could not extract, got '#{e}'. Going to next possible review entity."
          next arr
        end
        arr << val
        arr
      end
    end
  end
end

module Spider
  module Helpers
    # Slap non-element siblings together. Aka, all text gets clobbered together.
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