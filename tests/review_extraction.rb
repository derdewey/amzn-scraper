require 'bundler'
Bundler.require
require 'test/unit'

require '../spider_worker'
require '../spider_pool'
require '../amazon_review'
require 'logger'

LOGGER = Logger.new(STDOUT)
# LOGGER.level = Logger::DEBUG

class SingleReviewExtraction < Test::Unit::TestCase
  def setup
    @agent = Mechanize.new do |a|
      a.log = LOGGER
    end
    @page = Mechanize::Page.new(nil,{'content-type' => 'text/html'},File.read("single_review.html"),nil,@agent)
  end
  def test_star_rating
    @agent.log.level = Logger::ERROR
    command_stack = @page.extraction_lookup[:star_rating]
    assert_equal("5.0 out of 5 stars",@page.extract(command_stack))
  end
  def test_name
    LOGGER.level = Logger::ERROR
    command_stack = @page.extraction_lookup[:name]
    assert_equal("Billy Bob",@page.extract(command_stack))
  end
  def test_verified_purchase
    LOGGER.level = Logger::DEBUG
    command_stack = @page.extraction_lookup[:verified_purchase]
    assert_equal("Amazon Verified Purchase",@page.extract(command_stack))
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