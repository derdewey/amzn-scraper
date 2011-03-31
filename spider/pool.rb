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
    def working?
      @spiders.detect{|x| x.working?}
    end
    def join
      @spiders.each{|s| s.join}
    end
    def <<(spider)
      @spiders << spider
    end
    def [](index)
      return @spiders[index]
    end
    def start
      @logger.info "Starting #{@spiders.length} spider(s)"
      @spiders.each{|s| s.spawn}
      self
    end
    def stop
      @spiders.each{|s| s.stop}
    end
    def size
      @spiders.length
    end
  end
end