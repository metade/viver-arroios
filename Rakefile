require "json"
require "http"
require "rake/clean"

directory "tmp"

file "tmp/data.geojson" => "tmp" do
  # Get the Google My Maps ID from environment variable
  maps_id = ENV["MY_GOOGLE_MAPS_ID"]
  if maps_id.nil? || maps_id.empty?
    puts "Error: MY_GOOGLE_MAPS_ID environment variable is required"
    puts "Usage: MY_GOOGLE_MAPS_ID=your_map_id rake tmp/data.geojson"
    puts ""
    puts "To get your Google My Maps ID:"
    puts "1. Open your Google My Maps"
    puts "2. Click Share > View on web"
    puts "3. Copy the ID from the URL: https://www.google.com/maps/d/viewer?mid=YOUR_ID_HERE"
    exit 1
  end

  # Use the helper script to download and process the data
  puts "Using Google My Maps downloader script with http gem..."
  success = system("ruby scripts/download_maps.rb --maps-id #{maps_id} --output tmp/data.geojson --verbose")

  unless success
    puts "Error: Failed to download Google My Maps data"
    puts "Check the output above for specific error details"
    exit 1
  end
end

desc "Download and process Google My Maps data"
task download_maps: "tmp/data.geojson"

CLEAN.include("tmp/data.geojson")
