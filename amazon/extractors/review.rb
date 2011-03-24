module Amazon
  module Extractor
    module Review
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
         :price                  => [{:params => [:css, "div.cBoxInner > div.crProductInfo > table > tr > td + td > div.buyBlock > div.pricing"]},
                                     {:params => nil, :block => lambda do |node|
                                                                  span = node.css("span")
                                                                  if(span.first.nil?)
                                                                    node.text
                                                                  else
                                                                    span.text
                                                                  end
                                                                end},
                                     {:params => [:gsub,/\s{2,}/,' ']},
                                     {:params => [:strip]}
                                    ]
        }.freeze
      def review_extractors
        return REVIEW_EXTRACTION
      end
      def product_extractors
        return PRODUCT_EXTRACTION
      end
      def execute_command_stack(command_stack, nokogiri_doc = nil)
        # puts %Q{Extract called with command stack #{command_stack}}
        if(nokogiri_doc == nil)
          retval = parser
        else
          retval = nokogiri_doc
        end
      
        command_stack.each_with_index do |command,index|
          # puts "Excuting step #{index} #{command.inspect} being sent to a '#{retval.class}' (hint: '#{retval.to_s[0..75]}')"
          if(command[:params] && command[:block])
            retval = retval.send(*command[:params], &command[:block])
          elsif(command[:params].nil? && command[:block])
            retval = command[:block].call(retval)
          elsif(command[:params] && command[:block].nil?)
            retval = retval.send(*command[:params])
          else
            raise RuntimeError, "command stack entry makes no sense #{command}"
          end
        end
        return retval
      end
      def product_info
        extract_all([self],PRODUCT_EXTRACTION)
      end
      def reviews
        extract_all(review_nodes,REVIEW_EXTRACTION)
      end
      def review_nodes
        @review_nodes ||= self.execute_command_stack(REVIEW_MOST_COMMON_NODE) rescue []
      end
      def review_page?
        !review_nodes.empty?
      end
      def extract_all(nodes,conversion_rules)
        reviews = nodes.inject([]) do |arr,review|
          val = conversion_rules.inject({}) do |hash,entry|
            begin
              name, command_stack = entry
              hash[name] = self.execute_command_stack(command_stack,review)
              hash
            rescue => e
              LOG.debug "#{ e.message } - (#{ e.class })" unless LOG.nil?
              (e.backtrace or []).each{|x| LOG.debug "\t\t" + x}  unless LOG.nil?
              hash[name] = nil
              hash
            end
          end
          arr << val
          arr
        end
        reviews.delete_if{|x| x[:name].nil? || x[:name].empty? }
        reviews
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
      def self.normalize(str)
        str.send(:gsub,/\s{2,}/,' ')
      end
    end
  end
end

class Mechanize::Page
  include Amazon::Extractor::Review
end