#!/usr/bin/env ruby
puts "Going through #{ARGV[0].to_s} generations of #{ARGV[1]} concurrent crawlers"
ARGV[0].to_i.times do |gen|
	print gen.to_s
	pids = (0..ARGV[1].to_i).inject([]) do |arr,num|
		pid = Process.spawn("./spider.rb config.yaml")
		Process.detach(pid)
		arr << pid
		print "."; arr
	end
	puts
	begin
		sleep(180)
	rescue => e
		puts "Juggernaut cancelled! Stopping children.."
	ensure
                begin
			Process.kill("INT",*pids)
		rescue => e
			puts "Kill failed on #{pids.inspect}... whateves... keep going!"
		end
	end
end
