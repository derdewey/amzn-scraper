#!/usr/bin/env ruby
require 'rubygems'
require 'bundler'
Bundler.require
require 'mechanize'

a = Mechanize.new do |agent|
  agent.user_agent_alias = 'Mac Safari'
end

#root = %Q{http://www.amazon.com/books-used-books-textbooks/b/ref=sa_menu_bo0?&node=283155}
#
#categories = []
#
#a.get(root) do |page|
#  parser =  page.parser
#  parser.css('div.left_nav ul li a').inject(categories){|arr,ent| arr << {:name => ent.content, :url => ent['href']} }
#end

directory = %Q{http://www.amazon.com/Subjects-Books/b/ref=sv_b_1?ie=UTF8&node=1000}
categories = []
a.get(directory) do |page|
  parser = page.parser
  #parser.css('div.asinTextBlock div a').inject(categories){|arr,ent| arr << {:name => ent.content, :url => ent['href']}}
  parser.css('div.asinTextBlock div a').inject(categories){|arr,ent| arr << Mechanize::Page::Link.new(ent,a,page)}
end

puts categories

category = categories.first
a.click(category)

categories.each do |category_link|
  category_page = a.click(category_link)
  a.click category_page.link_with(:text => /Artists, A-Z/)
  
end
