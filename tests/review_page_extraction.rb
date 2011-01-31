require 'rubygems'
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
    @page = Mechanize::Page.new(nil,{'content-type' => 'text/html'},File.read("full_review_page.html"),nil,@agent)
  end
  def test_title
    @agent.log.level = Logger::ERROR
    command_stack = @page.product_extractors[:title]
    assert_equal("Switched (Trylle Trilogy, Book 1)",@page.extract(command_stack))
  end
end
