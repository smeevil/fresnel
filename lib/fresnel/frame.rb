

class Frame
  attr_accessor :header, :body, :footer, :output
  
  def initialize(options)
    @header=options[:header]||Array.new
    @body=options[:body]||String.new
    @footer=options[:footer]||Array.new
    @output=String.new
    
    line="+"
    (@@term_size-3).times{line+="-"}
    line+="+"

    collect=Array.new
    collect << line
    if header.any?
      header.each{|l|collect << l.chomp}
      collect << line
    end
    collect << ""
    collect += @body.chomp.wrap(@@term_size-5).split("\n")
    collect << ""
    collect << line
    if footer.any?
      footer.each{|l|collect << l.chomp}
      collect << line
    end
    
    collect.each do |l|
      self.output+="#{"| " unless l=~/^\+/}#{l.ljust(@@term_size-5)}#{" |" unless l=~/^\+/}\n"
    end
    
  end
  
  def to_s
    output
  end
end