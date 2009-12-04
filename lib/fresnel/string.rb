class String
  def wrap(col = 80)
    self.gsub(/(.{1,#{col}})( +|$\n?)|(.{1,#{col}})/,
      "\\1\\3\n")
  end

  def truncate(size)
    "#{self.strip[0..size]}#{"..." if self.size>size}"
  end
  
  def scrape_urls
    scan(/(http|https)(:\/\/)([a-zA-Z0-9.\/_-]+)| (www\.[a-zA-Z0-9.\/_-]+)/).map{ |url| url.join}
  end
end