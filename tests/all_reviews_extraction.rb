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
  def test_title
    @agent.log.level = Logger::INFO
    command_stack = @page.product_extractors[:title]
    assert_equal("Switched (Trylle Trilogy, Book 1)",@page.extract(command_stack))
  end
  def test_author_name
    @agent.log.level = Logger::INFO
    command_stack = @page.product_extractors[:author]
    assert_equal("Amanda Hocking",@page.extract(command_stack))
  end
  def test_price
    @agent.log.level = Logger::INFO
    command_stack = @page.product_extractors[:price]
    assert_equal("$0.99",@page.extract(command_stack))
  end
  def test_multiple_review_extractions
    @agent.log.level = Logger::DEBUG
    @page.extract_all_reviews
    # tree_search_params = @page.review_extractors[:verified_purchase][0]
    # raise @page.parser.send(*tree_search_params).length.inspect
  end
end
