require "./Rhythm"
require 'nokogiri'
require 'open-uri'
#require 'rexml/document'
#include REXML
puts "Hi"
spec = {:clientID => "1981696", :clientTag => "C695EDBB082367813EE5FF05AE3D58FF"}
puts "Hi2"
obj = Rhythm.new(spec)
puts "hi3"
obj.registerUser
puts "hi4"
#take in input
#Arguments:
#artistName
#songName (requires #artistName)
#genre
#returnCount (Default 10)
#focusPopularity (Default 500)
#focusSimilarity (Default 500)
#If user does not have one of these arguments, leave as ""
#xmlfile = obj.createStation(artistName, songName, genre = "")

xmlfile = obj.createStation("John Legend", "All Of Me", "")
puts "hi5"
doc = Nokogiri::XML(xmlfile)
puts "hi6"
thing = doc.xpath('//ALBUM').each do |thing|
    puts "Artist = " + thing.at_xpath('ARTIST').content
    puts "Album = " + thing.at_xpath('TITLE').content
end
thing2 = doc.xpath('//TRACK').each do |thing2|
    puts "Title = " + thing.at_xpath('TITLE').content
end

#albums = Array.new
#artists = Array.new
#songs = Array.new
#xmldoc.elements.each("RESPONSES/ALBUM") {
#	|e| puts "Hello"
#    albums.push e.attributes["TITLE"]
#	artists.push e.attributes["ARTIST"]
#}

#xmldoc.elements.each("RESPONSES/ALBUM/TRACK") {
#	|e| songs.push e.attributes["TITLE"]
#}
