require 'rubygems'
require 'twitter'
require 'placebot'
require 'is_gd'

httpauth = Twitter::HTTPAuth.new($settings.username, $settings.password)
twitter = Twitter::Base.new(httpauth)
twitter.replies(:since_id => settings.lastreply).each { |tweet|
  # Test to see if the tweet time is reasonably close to now, else apologise
  if false
    next
  end
  
  # Decipher the text
  begin
    case tweet.text
    when /what places are there\?/i
      puts "What places are there"
    when /help/i
      # Help info
    when /(when does|is) (.*) open\?/i
      place = whichPlace($2)
      puts "#{place.name} is ... "
    when /where is (.*)\?/i
      place = whichPlace($1)
      if not place.lat.nil? and not place.long.nil?
        twitter.direct_message_create(tweet.user.id,"Find #{place.name} on this map: "+IsGd.minify("maps.google.co.uk/maps?q=#{place.name}@#{place.lat},#{place.long}&z=19"))
      else
        twitter.direct_message_create(tweet.user.id,"I'm sorry, I don't know where #{place.name} is. My developer now knows to tell me!")
      end
    end
  rescue UnspecificPlaceError, PlaceNotKnownError
    twitter.direct_message_create(tweet.user.id,"I couldn't tell which place you were talking about, ask me 'what places are there?' and check your spelling!")
  end
  
  settings.lastreply = tweet.id
}