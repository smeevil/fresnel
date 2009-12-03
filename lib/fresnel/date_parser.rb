class DateParser
  def self.string(date)
    Date.today==Date.parse(date) ? DateTime.parse(date).strftime("Today %H:%M") : DateTime.parse(date).strftime("%d-%m-%y %H:%M")
  end
end