source "http://gemcutter.org/"
gem "redis"
gem "yajl-ruby", :require => "yajl/json_gem"
gem "SystemTimer"

if RUBY_PLATFORM.downcase =~ /darwin/
	gem "mechanize", :path => "/Users/xavierlange/code/mechanize"
else
	git "https://github.com/derdewey/mechanize.git" do
		gem "mechanize"
	end
end