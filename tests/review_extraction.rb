require 'bundler'
Bundler.require
require 'test/unit'

require '../spider_worker'
require '../spider_pool'
require '../amazon_review'

class SingleReviewExtraction < Test::Unit::TestCase
  def setup
    # @single_review =
    #   Nokogiri::HTML.parse(File.read("single_review.html"))
    @agent = Mechanize.new do |a|
    end
    @page = Mechanize::Page.new(nil,{'content-type' => 'text/html'},File.read("single_review.html"),nil,@agent)
  end
  def test_star_rating
    raise @page.extract_review
  end
end

class MultipleReviewExtraction < Test::Unit::TestCase
  # def setup
  #   @multiple_reviews =
  #     Nokogiri::HTML.parse(File.read("multiple_reviews.html"))
  # end
  # def test_multiple_reviews
  # end
end