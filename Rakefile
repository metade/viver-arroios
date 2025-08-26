require "json"
require "http"
require "rake/clean"

# Load the downloader class
require_relative "scripts/download_maps"

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

  # Use the GoogleMyMapsDownloader class directly
  puts "Downloading Google My Maps data using Ruby class..."
  downloader = GoogleMyMapsDownloader.new(
    maps_id: maps_id,
    output: "tmp/data.geojson",
    verbose: true
  )

  begin
    downloader.download_and_process
    puts "✅ Successfully downloaded and processed Google My Maps data!"
  rescue => e
    puts "❌ Error: #{e.message}"
    puts "Check that:"
    puts "  - Your map ID is correct"
    puts "  - Your map is publicly accessible"
    puts "  - You have GDAL installed"
    exit 1
  end
end

desc "Download and process Google My Maps data"
task download_maps: "tmp/data.geojson"

# Files to clean
CLEAN.include("tmp/data.geojson")
CLEAN.include("tmp/raw_data.kml")
CLEAN.include("tmp/temp_data.geojson")
