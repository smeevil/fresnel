class Cache
  attr_accessor :active, :timeout

  def initialize(options=Hash.new)
    @active=options[:active]||true
  end
  
  def self.clear_all
    `rm -rf /tmp/fresnel*.yml`
  end
  
  def timeout
    @@cache_timeout
  end
  def log(str)
    if @@debug
      puts str
    end
  end

  def create(options, &block)
    log "eval #{options[:action]}"
    if block
      data = block.call
    elsif options[:action]
      data=eval(options[:action])
    else
      raise ArgumentError, "No block or code to eval for a cache-able value"
    end
    log "creating cache file #{options[:name]}..."
    File.open("/tmp/fresnel_#{options[:name]}.yml",'w+'){ |f| f.write(YAML::dump(data)) }
    def data.age=(seconds)
      @age_in_seconds=seconds
    end
    def data.age
      @age_in_seconds
    end
    data.age=0
    return data
  end

  def load(options, &block)
    if self.active
      cache_timeout=options[:timeout]||@@cache_timeout
      log "caching is active !"
      if File.exists?("/tmp/fresnel_#{options[:name]}.yml")
        created_at=File.mtime("/tmp/fresnel_#{options[:name]}.yml")
        if (Time.now-created_at) < cache_timeout
          log "returning cached info (age : #{(Time.now-created_at).round}, timeout : #{cache_timeout})"
          data=YAML::load_file("/tmp/fresnel_#{options[:name]}.yml")
          def data.age=(seconds)
            @age_in_seconds=seconds
          end
          def data.age
            @age_in_seconds
          end
          data.age=(Time.now-created_at).round
          return data
        else
          log "refreshing data because the cached is older then the timeout (age : #{(Time.now-created_at).round}, timeout : #{cache_timeout})"
          self.create(options, &block)
        end
      else
        log "no cache data found, calling create..."
        self.create(options, &block)
      end
    else
      log "cache disabled, fetching life data (and creating cache file for future use...once cache is enabled)"
      self.create(options, &block)
    end
  end

  def clear(options)
    log "clearing cache /tmp/fresnel_#{options[:name]}.yml"
    File.delete("/tmp/fresnel_#{options[:name]}.yml") if File.exists?("/tmp/fresnel_#{options[:name]}.yml")
  end
end