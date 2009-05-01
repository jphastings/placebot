require "rubygems"
require "activerecord"
require 'placebot'

ActiveRecord::Schema.define do
  create_table(:places, :force => true) do |table|
    table.string :name, :null => false
    table.decimal :lat, :long, :null => true, :default => nil
    table.boolean :is_open,:null => false, :default => false
    table.integer :changes_at #The time the next change happens (mins from begining of day)
  end

  create_table(:days, :force => true) do |table|
    table.integer :place_id
    table.string :day, :null => false
    table.string :times, :null => false
  end
end

# Boots
place = Place.create(:name => "Boots",:lat => 52.938287, :long => -1.1946)
place.days.create(:day => "weekdays, termtime",:times =>"O:8.30,C:19.00")
place.days.create(:day => "saturday, termtime",:times =>"O:9.00,C:16.00")
place.days.create(:day => "weekdays, holidays",:times =>"O:8.30,C:17.30")
place.days.create(:day => "bank holidays",:times =>"")

# SU Shop
place = Place.create(:name => "The SU Shop",:lat => 52.93834, :long => -1.194508)
place.days.create(:day => "weekdays, termtime",:times =>"O:8.00,C:21.30")
place.days.create(:day => "saturday, termtime",:times =>"O:9.00,C:16.00")
place.days.create(:day => "weekdays, holidays",:times =>"O:8.30,C:17.30")