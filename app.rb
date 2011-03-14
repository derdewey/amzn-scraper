#!/usr/bin/env ruby
require 'rubygems'
require 'bundler'
Bundler.require
require 'resque'

module Demo
  class App < Sinatra::Base
    get '/' do
      info = Resque.info
      out = "<html><head><title>Resque Demo</title></head><body>"
      out << "<p>"
      out << "There are #{info[:pending]} pending and "
      out << "#{info[:processed]} processed jobs across #{info[:queues]} queues."
      out << "</p>"
      out << '&nbsp;&nbsp;<a href="/resque/overview">View Resque</a>'
      out
    end
  end
end
