$: << ".."

require 'rubygems'
require 'bundler'
Bundler.require
require 'test/unit'

require 'spider_worker'
require 'spider_pool'
require 'amazon_review'
require 'logger'

LOGGER = Logger.new(STDOUT)
# LOGGER.level = Logger::DEBUG

class AllReviewExtraction < Test::Unit::TestCase
  def setup
    @agent = Mechanize.new do |a|
      a.log = LOGGER
    end
    @page = Mechanize::Page.new(nil,{'content-type' => 'text/html'},File.read(File.dirname(__FILE__) + "/full_review_page.html"),nil,@agent)
  end
  def test_multiple_review_extractions
    @agent.log.level = Logger::INFO
    reviews = @page.reviews
    assert_not_equal(reviews,[])
    assert_kind_of(Array,reviews)
    assert_kind_of(Hash,reviews.first)
  end
  def test_review_page_test
    @agent.log.level = Logger::INFO
    assert_equal(@page.review_page?,true)
  end
end
