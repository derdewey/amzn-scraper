require 'rake/testtask'

task :default => [:test]

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['tests/*_test.rb']
  # t.ruby_opts = ['-rubygems'] if defined? Gem
  # t.ruby_opts << '-I.'
end
