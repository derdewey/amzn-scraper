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

stack = [category]

while l = stack.pop
  # Let's stay inside of amazon.com
  # next unless (l.uri.host.length == 0 || l.uri.host == a.history.first.uri.host)
  next unless (l.host.nil? || l.uri.host.empty?)
  puts "."
  stack.push(*(a.click(l).links)) unless a.visited?(l.href)
end
