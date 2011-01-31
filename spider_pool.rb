module Spider
  class Pool
    attr_writer :logger
    def initialize
      @spiders = []
      @logger = nil
    
      yield self if block_given?
    end
    def <<(spider)
      @logger.debug "Adding spider" if @logger
      @spiders << spider
    end
    def [](index)
      return @spiders[index]
    end
    def stop
      @logger.debug "Stopping spiders" if @logger
      puts "Please wait while #{@spiders.length} spiders are shut down"
      @spiders.each{|s| s.stop; print "."}
    end
    def start
      @logger.info "Starting all spiders" if @logger
      @spiders.each{|s| s.start}
      @spiders.each{|s| s.join}
      @logger.info "All spiders have stopped" if @logger
    end
  end
end