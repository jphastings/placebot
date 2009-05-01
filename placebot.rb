require 'rubygems'
require 'activerecord'
require 'yaml'

class Settings
  Defaults = {
    :username  => nil,
    :password  => nil,
    :lastreply => 1,
    :maintainer => nil,
    :db => {
      :adapter => "sqlite3",
      :dbfile  => "places.sqlite3"
    }
  }
  attr_accessor :lastreply
  attr_reader :username, :password, :db
  
  def initialize(file = "settings.yml")
    @file = file
    begin
      # Test to see if its a valid settings file
      open(@file) do |f|
        @s = YAML.load(f.read)
        @username = @s[:username]
        @password = @s[:password]
        # Check db exists!
        @db = @s[:db]
      end
    rescue
      open(@file,"w") do |f|
        f.write YAML.dump(Defaults)
      end
    end
  end
  
  def lastreply=(tweetid)
    if tweetid > @s[:lastreply]
      @s[:lastreply] = tweetid
      open(@file,"w") do |f|
        f.write YAML.dump(@s)
      end
    end
  end
  
  def lastreply
    @s[:lastreply]
  end
end

$settings = Settings.new
ActiveRecord::Base.establish_connection($settings.db)

class Place < ActiveRecord::Base
  has_many :days
  
  def changes_at
    (self[:changes_at]/60).to_i.to_s+":"+(self[:changes_at]%60).to_s.rjust(2,"0")
  end
end

class Day < ActiveRecord::Base
  belongs_to :place
end

class PlaceNotKnownError < StandardError; end
class UnspecificPlaceError <StandardError; end

# From http://snippets.dzone.com/posts/show/5147
class Array
  def add_condition(condition, conjunction='and')
    if condition.is_a? Array
      if self.empty?
        (self << condition).flatten!
      else
        self[0] += " #{conjunction} " + condition.shift
        (self << condition).flatten!
      end
    elsif condition.is_a? String
      self[0] += " #{conjunction} " + condition
    else
      raise "don't know how to handle this condition type"
    end
    self
  end
end

# Will hunt for a listed place by name
# Throws custom errors if too many or too few places are found
def whichPlace string
  results = Place.find(:all,:conditions => [ "name LIKE ?", string])
  case results.length
  when 0
    raise PlaceNotKnownError, "I do not know that place"
  when 1
    return results.first
  else
    # Suggestions?
    raise UnspecificPlaceError, "Your place is unspecific"
  end
end