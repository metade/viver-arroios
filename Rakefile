require "json"
require "http"
require "rake/clean"

# Load the downloader class
require_relative "scripts/download_maps"

directory "tmp"

file "tmp/propostas.geojson" => "tmp" do
  # Get the Google My Maps ID from environment variable
  maps_id = ENV["MY_GOOGLE_MAPS_ID"]
  if maps_id.nil? || maps_id.empty?
    puts "Error: MY_GOOGLE_MAPS_ID environment variable is required"
    puts "Usage: MY_GOOGLE_MAPS_ID=your_map_id rake tmp/propostas.geojson"
    puts ""
    puts "To get your Google My Maps ID:"
    puts "1. Open your Google My Maps"
    puts "2. Click Share > View on web"
    puts "3. Copy the ID from the URL: https://www.google.com/maps/d/viewer?mid=YOUR_ID_HERE"
    exit 1
  end

  # Use the GoogleMyMapsDownloader class directly
  puts "Downloading Google My Maps data for 'propostas' layer..."
  downloader = GoogleMyMapsDownloader.new(
    maps_id: maps_id,
    layer_name: "propostas",
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

file "tmp/data.pmtiles" => ["tmp/propostas.geojson"] do
  # Check if tippecanoe is available
  unless system("which tippecanoe > /dev/null 2>&1")
    puts "Error: Tippecanoe is required but not found"
    puts "Install with: brew install tippecanoe (macOS) or build from source"
    exit 1
  end

  cmd = [
    "tippecanoe",
    "-Z", "0", "-z", "12",
    "--no-feature-limit",
    "--no-tile-size-limit",
    "--simplification=1",
    "-o", task.name
  ] + task.sources

  stdout, stderr, status = Open3.capture3(*cmd)
  $stdout.print stdout
  $stderr.print stderr

  puts "✅ Successfully generated PMTiles: tmp/data.pmtiles"
  puts "   Layers included: #{task.sources.map { |f| File.basename(f, ".geojson") }.join(", ")}"
  puts "   File size: #{File.size("tmp/data.pmtiles")} bytes"
end

desc "Download data and generate PMTiles (full workflow)"
task build: "tmp/data.pmtiles"

# Files to clean
CLEAN.include("tmp/*.geojson")
CLEAN.include("tmp/raw_data.kml")
CLEAN.include("tmp/temp_data.geojson")
CLEAN.include("tmp/data.pmtiles")
