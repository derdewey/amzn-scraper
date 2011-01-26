#!/usr/bin/env ruby
raise ArgumentError, "Must provide number of worker threads" if ARGV.empty?

require 'rubygems'
require 'bundler'
Bundler.require

require 'logger'
require 'mechanize'
require 'redis'
require 'digest/sha1'
require 'json'

require 'constants'
require 'spider_worker'
require 'spider_pool'
require 'amazon_review'

LOG = Logger.new(STDOUT)
LOG.level = Logger::INFO

LOG.info "Creating spider pool"
POOL = Spider::Pool.new do |pool|
  pool.logger = LOG
end
LOG.error "Spider with #{ARGV[0]} workers"
ARGV[0].to_i.times do |num|
  POOL << Mechanize.new do |agent|
    agent.user_agent_alias = 'Mac Safari'
    agent.redis = Redis.new(:host => "localhost", :port => 6379, :thread_safe => true)
    agent.log = LOG
    agent.init_state_mutex
  end
end

Signal.trap("INT") do 
  POOL.stop
end
POOL.start

# <!-- BOUNDARY -->
# <a name="RVU65VLXPRL8N"></a><br />
# 
# 
# <div style="margin-left:0.5em;">
#     
#       <div style="margin-bottom:0.5em;">
#         43 of 53 people found the following review helpful:
#       </div>
#       <div style="margin-bottom:0.5em;">
#         <span style="margin-right:5px;"><span class="swSprite s_star_5_0 " title="5.0 out of 5 stars" ><span>5.0 out of 5 stars</span></span> </span>
#         <span style="vertical-align:middle;"><b>A brave and necessary book</b>, <nobr>March 10, 2010</nobr></span>
# 
#       </div>
#       <div style="margin-bottom:0.5em;">
#         <div><div style="float:left;">By&nbsp;</div><div style="float:left;"><a name="A1G5X6ABE4JEJR|sUb|1" onmouseover="if (jQuery.CustomerPopover) jQuery.CustomerPopover.bind(this);" href="http://www.amazon.com/gp/pdp/profile/A1G5X6ABE4JEJR/ref=cm_cr_pr_pdp" ><span style = "font-weight: bold;">Mark Crispin <span style="white-space: nowrap;">Miller<span class="swSprite s_chevron custPopRight" ></span></span></span></a> (New York, N.Y.)  - <a href="http://www.amazon.com/gp/cdp/member-reviews/A1G5X6ABE4JEJR/ref=cm_cr_pr_auth_rev?ie=UTF8&amp;sort_by=MostRecentReview">See all my reviews</a></div></div><div style="clear:both;"></div>
#       </div>
#       <div class="tiny" style="margin-bottom:0.5em;">
#         <b><span class="h3color tiny">This review is from: </span>American Conspiracies: Lies, Lies, and More Dirty Lies that the Government Tells Us (Hardcover)</b>
# 
#       </div>
# 
# It's a good thing that Jesse Ventura (along with Dick Russell, his meticulous co-author) came out with this book. First of all, he has the guts to do it--a sort of courage that is all too rare among the types (i.e., journalists and academics) who _should_ be rigorously questioning official lies as he's done here. And it's also lucky that Ventura co-authored AMERICAN CONSPIRACIES because he has the sort of star power that ensures a fair amount of mainstream media exposure (although he'd certainly get plenty more if he'd come out with, say, a tell-all about other wrestlers and/or politicians). So many good Americans will hear a lot of things that they should know.
# <br />
# <br />And that's precisely why this book provokes the sort of snide and sweeping put-down that we see in some of these Amazon reviews (although so far just a few), and that we're sure to hear from mainstream voices, both far-right and "liberal." The point of such derision certainly is _not_ to help us grasp some truth: on the contrary. Its point is to discourage you, and everybody else, from even bothering to read AMERICAN CONSPIRACIES. 
# <br />
# <br />So I would urge you to get hold of it, and read it--and, most important, look into all these matters for yourself. I doubt that the book's authors would want anyone just to swallow everything they say (unlike rabble-rousers like Glenn Beck and Rush Limbaugh, who _do_ promote "conspiracy theories" without any basis in reality). Read it, and then follow up, both by looking into these forbidden stories, and by urging others to look into them as well.
#       <div style="padding-top: 10px; clear: both; width: 100%;">
# 
#         <div style="float:left; padding-right:15px; border-right:1px solid #CCCCCC"><div style="padding-bottom:5px;"><b class="tiny" style="color:#666666;white-space:nowrap;">Help other customers find the most helpful reviews</b>&nbsp;</div><div style="width:300px;">
# 
# 
# 
# 
# 
# 
# 
# 
# <a name="RVU65VLXPRL8N.2115.Helpful.Reviews" style="font-size:1px;"> </a><span
# class="crVotingButtons"><nobr><span class="votingPrompt">Was this review helpful to you?&nbsp;</span><a rel="nofollow" class="votingButtonReviews" href="http://www.amazon.com/gp/voting/cast/Reviews/2115/RVU65VLXPRL8N/Helpful/1/ref=cm_cr_prvoteyn?ie=UTF8&token=662FAB58D54259457AB8F6E591D7A8AAEF832501&target=aHR0cDovL3d3dy5hbWF6b24uY29tL3Jldmlldy8xNjAyMzk4MDJYL3JlZj1jbV9jcl9wcnZvdGVyZHI_X2VuY29kaW5nPVVURjgmc2hvd1ZpZXdwb2ludHM9MQ&voteAnchorName=RVU65VLXPRL8N.2115.Helpful.Reviews&voteSessionID=181-0146297-6915413"><span class="cmtySprite s_largeYes " ><span>Yes</span></span></a>
# <a rel="nofollow" class="votingButtonReviews" href="http://www.amazon.com/gp/voting/cast/Reviews/2115/RVU65VLXPRL8N/Helpful/-1/ref=cm_cr_prvoteyn?ie=UTF8&token=2A5B98E4802A88F5AA0EC012D9EC9BBB8425C508&target=aHR0cDovL3d3dy5hbWF6b24uY29tL3Jldmlldy8xNjAyMzk4MDJYL3JlZj1jbV9jcl9wcnZvdGVyZHI_X2VuY29kaW5nPVVURjgmc2hvd1ZpZXdwb2ludHM9MQ&voteAnchorName=RVU65VLXPRL8N.2115.Helpful.Reviews&voteSessionID=181-0146297-6915413"><span class="cmtySprite s_largeNo " ><span>No</span></span></a></nobr> <span class="votingMessage"></span></span>
# 
# </div></div><div style="float:left;"><div style="padding-left:15px;"><div style="white-space:nowrap;"><span class='tiny'>
# 
# 
# 
# <a name="RVU65VLXPRL8N.2115.Inappropriate.Reviews" style="font-size:1px;"> </a><span class="reportingButton"><nobr><a rel="nofollow" class="reportingButton" href="http://www.amazon.com/gp/voting/cast/Reviews/2115/RVU65VLXPRL8N/Inappropriate/1/ref=cm_cr_prvoteyn?ie=UTF8&token=408876187030EB34E2F5D77CA658A8CABDA16A3C&target=aHR0cDovL3d3dy5hbWF6b24uY29tL3Jldmlldy8xNjAyMzk4MDJYL3JlZj1jbV9jcl9wcnZvdGVyZHI_X2VuY29kaW5nPVVURjgmc2hvd1ZpZXdwb2ludHM9MQ&voteAnchorName=RVU65VLXPRL8N.2115.Inappropriate.Reviews&voteSessionID=181-0146297-6915413"
# onclick="var w = window.open(this.href+'&type=popup','reportAbuse','height=380,width=580');w.focus();return false;">Report abuse</a></nobr></span>
# </span> <span style="color:#CCCCCC;">|</span> <span class="tiny"><a href="http://www.amazon.com/review/RVU65VLXPRL8N/ref=cm_cr_pr_perm?ie=UTF8&ASIN=160239802X&nodeID=&tag=&linkCode=" >Permalink</a></span></div><div style="white-space:nowrap;padding-left:-5px;padding-top:5px;"><a href="http://www.amazon.com/review/RVU65VLXPRL8N/ref=cm_cr_pr_cmt?ie=UTF8&ASIN=160239802X&nodeID=&tag=&linkCode=#wasThisHelpful" ><span class="swSprite s_comment " ><span>Comment</span></span></a>&nbsp;<a href="http://www.amazon.com/review/RVU65VLXPRL8N/ref=cm_cr_pr_cmt?ie=UTF8&ASIN=160239802X&nodeID=&tag=&linkCode=#wasThisHelpful" >Comment</a></div></div></div><div style="clear:both;"></div>
#       </div>
#       <br />
# 
# </div>
# 
