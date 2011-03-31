$: << File.dirname(__FILE__)
require 'rubygems'
require 'bundler'
Bundler.require
require 'test/unit'

require 'spider/pool'
require 'spider/worker'
require 'amazon/extractors/review'
require 'logger'

require 'test_helpers'

LOG = LOGGER
class ReviewExtractionTest < Test::Unit::TestCase
  include TestHelpers
  def setup
    @agent = Mechanize.new do |a|
    end
  end
  def test_review_sets_with_single_paragraph_bodies
    @page = load_page(@agent,"0743524918_pg_10.html")
    reviews = @page.reviews
    assert_not_nil(reviews)
    assert_equal(reviews.length,3)
    
    ellie = reviews[0]
    assert_equal(ellie[:name],"Ellie")
    assert_match(%r{^This is the first time},ellie[:review_body])
    assert_match(%r{optimism$},ellie[:review_body])
    assert_equal("Positively Disturbing",ellie[:review_title])
    assert_equal(false,ellie[:real_name])
    assert_equal("0743222989",ellie[:cross_referenced_from])
    assert_equal("AFEIT31PJ121Z",ellie[:user_id])
    assert_equal("July 20, 2006",ellie[:date])
    
    mccoy = reviews[1]
    assert_equal(mccoy[:name],"P. McCoy")
    assert_match(%r{^Unfortunately},mccoy[:review_body])
    assert_match(%r{penny.$},mccoy[:review_body])
    assert_equal("Authentic Happiness? Not Hardly...",mccoy[:review_title])
    assert_equal(true,mccoy[:real_name])
    assert_equal("0743222989",mccoy[:cross_referenced_from])
    assert_equal("A17YR6U9AKU46Y",mccoy[:user_id])
    assert_equal("May 1, 2006",mccoy[:date])
    
    marcelo = reviews[2]
    assert_equal(marcelo[:name],"Marcelo A. Garcia \"molho\"")
    assert_match(%r{^one should},marcelo[:review_body])
    assert_match(%r{MR!!!$},marcelo[:review_body])
    assert_equal("cruel fake emotions",marcelo[:review_title])
    assert_equal(true,marcelo[:real_name])
    assert_equal("0743222989",marcelo[:cross_referenced_from])
    assert_equal("A26PT9Q3JUURHH",marcelo[:user_id])
    assert_equal("February 17, 2009",marcelo[:date])
  end
end