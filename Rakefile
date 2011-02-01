task :default => [:test]

desc "Test the mechanize system"
task :test do
  Dir.glob("tests/**.rb").each do |filename|
    puts "requiring #{filename}"
    require filename
  end
end
