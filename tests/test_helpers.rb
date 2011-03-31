# Some common code between unit tests

LOGGER = Logger.new(STDOUT)
LOGGER.level = Logger::INFO

module TestHelpers
  def load_page(agent,filename)
    Mechanize::Page.new(nil,{'content-type' => 'text/html'},File.read(File.dirname(__FILE__) + "/html/" + filename),nil,agent)
  end
end
