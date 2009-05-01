require "time"
require "placebot"
require 'twitter'

$weekdays = ["sunday","monday","tuesday","wednesday","thursday","friday","saturday"].freeze
$bankholiday = open("uk.bankholidays.list") { |f| f.readlines.include?(Time.now.strftime("%Y-%m-%d\n")) }

httpauth = Twitter::HTTPAuth.new($settings.username, $settings.password)
$twitter = Twitter::Base.new(httpauth)

def timetomins(time)
  time = time.split(".")
  return time[0].to_i*60 + time[1].to_i
end

def nowandnext(placeid)
  place = Place.find(placeid)
  # Today
  conditions = ["place_id = ?",placeid]
  #  2009-01-01 (date)
  conditions.add_condition(['(day = ?', Time.now.strftime("%Y-%m-%d")])
  #  Bank holidays
  conditions.add_condition(['(day = ?', "bankholiday"]) if $bankholiday
  # Is it termtime?
  termtime = ", termtime"
  # Day of the week
  weekday = Time.now.strftime("%w").to_i
  conditions.add_condition(['day = ?', $weekdays[weekday]+termtime],"or")
  conditions.add_condition(['day = ?', 'weekdays'+termtime],"or") if weekday != 0 and weekday != 6
  
  conditions.add_condition ['1)']
  day = Day.find(:first,:include => :place,:select => "place_id,days.times",:conditions => conditions, :order => "days.day ASC").times.split(",")
  nowopen = place.is_open
  nextchange = nil
  day.collect{|time| time.split(":") }.each do |time|
    if timetomins(time[1]) < timetomins(Time.now.strftime("%H.%M"))
      nowopen = (time[0] == "O") 
    else
      nextchange = timetomins(time[1])
      break
    end
  end
  Place.update(placeid,{:is_open => nowopen,:changes_at =>nextchange})
  
  if place.is_open != nowopen
    if place.is_open.nil?
      $twitter.update("New place: #{place.name}! It is currently #{((nowopen)? "open" : "closed")}.")
    else
      $twitter.update("#{place.name} is now #{((nowopen)? "open" : "closed")}.")
    end
  end
  
  if not place.is_open and (nextchange - timetomins(Time.now.strftime("%H.%M"))) == 30
    $twitter.update("#{place.name} closes in half an hour.")
  end
end

Place.find(:all).each do |place|
  nowandnext(place.id)
end