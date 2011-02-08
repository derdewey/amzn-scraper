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

class SingleReviewExtraction < Test::Unit::TestCase
  def setup
    @agent = Mechanize.new do |a|
      a.log = LOGGER
    end
    @page = Mechanize::Page.new(nil,{'content-type' => 'text/html'},File.read(File.dirname(__FILE__) + "/single_review.html"),nil,@agent)
  end
  def test_star_rating
    @agent.log.level = Logger::ERROR
    command_stack = @page.review_extractors[:star_rating]
    assert_equal(5.0,@page.execute_command_stack(command_stack))
  end
  def test_name
    LOGGER.level = Logger::ERROR
    command_stack = @page.review_extractors[:name]
    assert_equal("Billy Bob",@page.execute_command_stack(command_stack))
  end
  def test_verified_purchase
    LOGGER.level = Logger::ERROR
    command_stack = @page.review_extractors[:verified_purchase]
    assert_equal(true,@page.execute_command_stack(command_stack))
  end
  def test_cross_referenced_from
    LOGGER.level = Logger::ERROR
    command_stack = @page.review_extractors[:cross_referenced_from]
    assert_equal("Switched (Trylle Trilogy, Book 1) (Kindle Edition)",@page.execute_command_stack(command_stack))
  end
  def test_review_body
    LOGGER.level = Logger::ERROR
    command_stack = @page.review_extractors[:review_body]
    assert_equal("BLARP BLARP MULTILINE FANCINESS",@page.execute_command_stack(command_stack))
  end
end
