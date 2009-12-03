class Color
  def self.print(string,prio="")
    if COLOR
      return "#{HighLine::WHITE}#{string}#{HighLine::CLEAR}" if string.nil?
      case prio
        when /high/
          return "#{HighLine::RED}#{string}#{HighLine::CLEAR}"
        when /medium/
          return "#{HighLine::YELLOW}#{string}#{HighLine::CLEAR}"
        when /low/
          return "#{HighLine::GREEN}#{string}#{HighLine::CLEAR}"
        else
          return "#{HighLine::WHITE}#{string}#{HighLine::CLEAR}"
      end
    else
      return string
    end
  end
end