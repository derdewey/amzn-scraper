module Review
  module Amazon
    REVIEW_EXTRACTION =
      {
       :star_rating           => [[:css, "a + br + div > div + div > span > span > span"],[:text]],
       :name                  => [[:css, "a + br + div > div + div + div > div > div + div > a > span"],[:text]],
       :verified_purchase     => [[:css, "a + br + div > div + div + div > span > b"],[:text]],
       :cross_referenced_from => [[:css, "a + br + div > div + div + div + div + div > b > span"],[:first],[:next_sibling],[:text],[:gsub!,/\s{2,}/,' '],[:strip!]],
       :review_body           => [[:css, "a + br + div > div + div + div + div + div"],[:first],[:next_sibling],[:text],[:gsub!,/\s{2,}/,' '],[:strip!]]
      }.freeze
    PRODUCT_EXTRACTION =
    {
      :title                  => [[:css, "body > table > tr > td > h1 + div > h1 + div > h1 > a"],[:text],[:gsub!,/\s{2,}/,' '],[:strip!]],
      :author                 => [[:css, ""]]
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
      @mech.log.debug "Extract returning '#{retval}'"
      return retval
    end
  end
end

class Mechanize::Page
  include Review::Amazon
end