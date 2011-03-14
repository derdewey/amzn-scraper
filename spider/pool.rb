module Spider
  class Pool
    attr_writer :logger
    attr_accessor :spiders
    def initialize(opts)
      opts = {}.merge(opts)
      @spiders = []
      @logger = opts[:logger]
    
      yield self if block_given?
      
      Signal.trap("INT") do
        puts
        LOG.info "Please wait while #{@spiders.length} spiders are shut down"
        stop
      end
      @alive=true
      @shutdown_thread = Thread.new do
        while(@alive ||= true) do
          sleep(1)
        end
      end
    end
    def join
      @shutdown_thread.join
    end
    def <<(spider)
      @spiders << spider
    end
    def [](index)
      return @spiders[index]
    end
    def start
      @logger.info "Starting #{@spiders.length} spider(s)" if @logger
      @spiders.each{|s| s.spawn}
    end
    def stop
      @spiders.each{|s| s.stop}
      @spiders.each{|s| s.join}
    end
    def alive?
      @spiders.each{|s| s.running?}
    end
  end
end