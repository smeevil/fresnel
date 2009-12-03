class Cache
  attr_accessor :active, :timeout

  def initialize(options)
    @active=options[:active]
    @timeout=options[:timeout]
  end

  def log(str)
    if DEBUG
      puts str
    end
  end
  
  def create(options)
    log "eval #{options[:action]}"
    data=eval(options[:action])
    log "creating cache file #{options[:name]}..."
    File.open("/tmp/fresnel_#{options[:name]}.yml",'w+'){ |f| f.write(YAML::dump(data)) }
    return data
  end

  def load(options)
    if self.active
      cache_timeout=options[:timeout]||self.timeout
      log "caching is active !"
      if File.exists?("/tmp/fresnel_#{options[:name]}.yml")
        created_at=File.mtime("/tmp/fresnel_#{options[:name]}.yml")
        if (Time.now-created_at) < cache_timeout
          log "returning cached info (age : #{(Time.now-created_at).round}, timeout : #{cache_timeout})"
          YAML::load_file("/tmp/fresnel_#{options[:name]}.yml")
        else
          log "refreshing data because the cached is older then the timeout (age : #{(Time.now-created_at).round}, timeout : #{cache_timeout})"
          self.create(options)
        end
      else
        log "no chache data found, calling create..."
        create(options)
      end
    else
      log "cache disabled, fetching life data (and creating cache file for future use...once cache is enabled)"
      self.create(options)
    end
  end

  def clear(options)
    log "clearing cache /tmp/fresnel_#{options[:name]}.yml"
    File.delete("/tmp/fresnel_#{options[:name]}.yml") if File.exists?("/tmp/fresnel_#{options[:name]}.yml")
  end
end