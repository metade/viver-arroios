#!/usr/bin/env ruby

require "http"
require "json"
require "optparse"

class GoogleMyMapsDownloader
  def initialize(options = {})
    @verbose = options[:verbose] || false
    @output_file = options[:output] || "tmp/data.geojson"
    @maps_id = options[:maps_id]
  end

  def download_and_process
    validate_requirements
    download_kml
    convert_to_geojson
    filter_features
    cleanup
    print_summary
  end

  private

  def log(message)
    puts message if @verbose
  end

  def validate_requirements
    if @maps_id.nil? || @maps_id.empty?
      puts "Error: Google My Maps ID is required"
      puts "Usage: ruby scripts/download_maps.rb --maps-id YOUR_MAP_ID"
      exit 1
    end

    # Check if GDAL is available
    unless system("which ogr2ogr > /dev/null 2>&1")
      puts "Error: GDAL/OGR is required but not found"
      puts "Install with: brew install gdal (macOS) or apt-get install gdal-bin (Ubuntu)"
      exit 1
    end

    # Check if http gem is available
    begin
      require "http"
    rescue LoadError
      puts "Error: http gem is required but not found"
      puts "Install with: bundle install"
      exit 1
    end

    # Ensure tmp directory exists
    Dir.mkdir("tmp") unless Dir.exist?("tmp")
  end

  def download_kml
    url = "https://www.google.com/maps/d/kml?mid=#{@maps_id}&forcekml=1"
    log "Downloading KML from: #{url}"

    begin
      response = HTTP.timeout(30)
        .follow(max_hops: 5)
        .headers(
          "User-Agent" => "Mozilla/5.0 (compatible; Jekyll Map Downloader)",
          "Accept" => "application/vnd.google-earth.kml+xml,application/xml,text/xml,*/*"
        )
        .get(url)

      if response.code != 200
        puts "Error: Failed to download map data (HTTP #{response.code})"
        puts "Possible issues:"
        puts "  - Map is not publicly accessible"
        puts "  - Invalid map ID"
        puts "  - Network connectivity issues"
        exit 1
      end

      @kml_data = response.body.to_s
      log "Downloaded #{@kml_data.length} bytes of KML data"

      # Basic validation that we got KML content
      unless @kml_data.match?(/<\?xml|<kml/i)
        puts "Error: Downloaded content doesn't appear to be valid KML"
        puts "Content preview: #{@kml_data[0..200]}..."
        exit 1
      end

      # Save raw KML for debugging
      File.write("tmp/raw_data.kml", @kml_data)
      log "Raw KML saved to tmp/raw_data.kml"
    rescue HTTP::Error => e
      puts "Error: HTTP request failed - #{e.message}"
      puts "This might be due to:"
      puts "  - Network connectivity issues"
      puts "  - Timeout (large maps take longer to download)"
      puts "  - Google Maps service temporary issues"
      exit 1
    rescue => e
      puts "Error: Unexpected error during download - #{e.message}"
      exit 1
    end
  end

  def convert_to_geojson
    log "Converting KML to GeoJSON using ogr2ogr..."

    conversion_success = system("ogr2ogr -f GeoJSON tmp/temp_data.geojson tmp/raw_data.kml 2>/dev/null")

    unless conversion_success && File.exist?("tmp/temp_data.geojson")
      puts "Error: Failed to convert KML to GeoJSON"
      puts "This might happen if:"
      puts "  - The KML file is empty or corrupted"
      puts "  - GDAL version compatibility issues"
      exit 1
    end

    @geojson_data = JSON.parse(File.read("tmp/temp_data.geojson"))
    log "Converted to GeoJSON with #{@geojson_data["features"].length} features"
  end

  def filter_features
    log "Filtering features for valid coordinates..."

    @valid_features = @geojson_data["features"].select do |feature|
      validate_feature_geometry(feature)
    end

    log "Filtered #{@geojson_data["features"].length} features down to #{@valid_features.length} valid features"

    # Create the final GeoJSON structure
    filtered_geojson = {
      "type" => "FeatureCollection",
      "name" => "Google My Maps Data (#{@maps_id})",
      "crs" => {
        "type" => "name",
        "properties" => {
          "name" => "urn:ogc:def:crs:OGC:1.3:CRS84"
        }
      },
      "features" => @valid_features
    }

    # Write the final GeoJSON file
    File.write(@output_file, JSON.pretty_generate(filtered_geojson))
    log "Saved filtered GeoJSON to #{@output_file}"
  end

  def validate_feature_geometry(feature)
    geometry = feature["geometry"]
    return false if geometry.nil? || geometry["coordinates"].nil?

    case geometry["type"]
    when "Point"
      validate_point_coordinates(geometry["coordinates"])
    when "LineString"
      validate_linestring_coordinates(geometry["coordinates"])
    when "Polygon"
      validate_polygon_coordinates(geometry["coordinates"])
    when "MultiPoint"
      geometry["coordinates"].all? { |coords| validate_point_coordinates(coords) }
    when "MultiLineString"
      geometry["coordinates"].all? { |coords| validate_linestring_coordinates(coords) }
    when "MultiPolygon"
      geometry["coordinates"].all? { |coords| validate_polygon_coordinates(coords) }
    else
      false
    end
  end

  def validate_point_coordinates(coords)
    coords.is_a?(Array) && coords.length >= 2 &&
      coords[0].is_a?(Numeric) && coords[1].is_a?(Numeric) &&
      coords[0].between?(-180, 180) && coords[1].between?(-90, 90)
  end

  def validate_linestring_coordinates(coords)
    coords.is_a?(Array) && coords.length >= 2 &&
      coords.all? { |point| validate_point_coordinates(point) }
  end

  def validate_polygon_coordinates(coords)
    coords.is_a?(Array) && coords.all? do |ring|
      ring.is_a?(Array) && ring.length >= 4 &&
        ring.all? { |point| validate_point_coordinates(point) } &&
        ring.first == ring.last  # Ensure ring is closed
    end
  end

  def cleanup
    ["tmp/raw_data.kml", "tmp/temp_data.geojson"].each do |file|
      File.delete(file) if File.exist?(file)
    end
    log "Cleaned up temporary files"
  end

  def print_summary
    file_size = File.size(@output_file)
    puts "✅ Successfully processed Google My Maps data!"
    puts "   📍 Map ID: #{@maps_id}"
    puts "   📊 Valid features: #{@valid_features.length}"
    puts "   💾 File size: #{format_file_size(file_size)}"
    puts "   📁 Output: #{@output_file}"

    # Show feature type breakdown
    feature_types = @valid_features.group_by { |f| f["geometry"]["type"] }
    feature_types.each do |type, features|
      puts "   └─ #{type}: #{features.length} features"
    end
  end

  def format_file_size(bytes)
    if bytes < 1024
      "#{bytes} bytes"
    elsif bytes < 1024 * 1024
      "#{(bytes / 1024.0).round(1)} KB"
    else
      "#{(bytes / (1024.0 * 1024)).round(1)} MB"
    end
  end
end

# Command line interface
if __FILE__ == $0
  options = {}

  OptionParser.new do |opts|
    opts.banner = "Usage: ruby scripts/download_maps.rb [options]"

    opts.on("-m", "--maps-id ID", "Google My Maps ID (required)") do |id|
      options[:maps_id] = id
    end

    opts.on("-o", "--output FILE", "Output GeoJSON file (default: tmp/data.geojson)") do |file|
      options[:output] = file
    end

    opts.on("-v", "--verbose", "Verbose output") do
      options[:verbose] = true
    end

    opts.on("-h", "--help", "Show this help") do
      puts opts
      puts
      puts "Examples:"
      puts "  ruby scripts/download_maps.rb --maps-id 1BvNertbkuieuJHi8kmzKuDy4kbD2TINm4"
      puts "  ruby scripts/download_maps.rb -m 1BvNertbkuieuJHi8kmzKuDy4kbD2TINm4 -v"
      puts "  MY_GOOGLE_MAPS_ID=1BvNertbkuieuJHi8kmzKuDy4kbD2TINm4 ruby scripts/download_maps.rb"
      exit
    end
  end.parse!

  # Allow maps ID to be set via environment variable
  options[:maps_id] ||= ENV["MY_GOOGLE_MAPS_ID"]

  downloader = GoogleMyMapsDownloader.new(options)
  downloader.download_and_process
end
