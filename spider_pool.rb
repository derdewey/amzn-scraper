module Spider
  class Pool
    attr_writer :logger
    attr_accessor :spiders
    def initialize(opts)
      opts = {}.merge(opts)
      @spiders = []
      @logger = opts[:logger]
    
      yield self if block_given?
    end
    def <<(spider)
      @logger.debug "Adding spider" if @logger
      @spiders << spider
    end
    def [](index)
      return @spiders[index]
    end
    def start
      @logger.info "Starting #{@spiders.length} spider(s)" if @logger
      @spiders.each{|s| s.start}
    end
    def stop
      @spiders.each{|s| s.stop}
      @spiders.each{|s| s.join}
    end
  end
end