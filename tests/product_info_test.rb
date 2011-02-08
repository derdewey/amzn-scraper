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

class ProductInfoTest < Test::Unit::TestCase
  def setup
    @agent = Mechanize.new do |a|
      a.log = LOGGER
    end
    @page = Mechanize::Page.new(nil,{'content-type' => 'text/html'},File.read(File.dirname(__FILE__) + "/full_review_page.html"),nil,@agent)
  end
  def test_title
    @agent.log.level = Logger::INFO
    command_stack = @page.product_extractors[:title]
    assert_equal("Switched (Trylle Trilogy, Book 1)",@page.execute_command_stack(command_stack))
  end
  def test_author_name
    @agent.log.level = Logger::INFO
    command_stack = @page.product_extractors[:author]
    assert_equal("Amanda Hocking",@page.execute_command_stack(command_stack))
  end
  def test_price
    @agent.log.level = Logger::INFO
    command_stack = @page.product_extractors[:price]
    assert_equal("$0.99",@page.execute_command_stack(command_stack))
  end
  # def test_product_info
  #   @agent.log.level = Logger::INFO
  #   raise @page.product_info.inspect
  # end
  # def test_product_page?
  #   @agent.log.level = Logger::INFO
  #   assert_equal(true,@page.product_page?)
  # end
end
