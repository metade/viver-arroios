#!/usr/bin/env ruby

require "http"
require "json"

class GoogleMyMapsDownloader
  attr_reader :valid_features, :maps_id, :output_file, :layer_name

  def initialize(maps_id:, layer_name: "propostas", output: nil, verbose: false)
    @verbose = verbose
    @layer_name = layer_name
    @output_file = output || "tmp/#{layer_name}.geojson"
    @maps_id = maps_id
    @kml_data = nil
    @geojson_data = nil
    @valid_features = []
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
      raise "Google My Maps ID is required"
    end

    # Check if GDAL is available
    unless system("which ogr2ogr > /dev/null 2>&1")
      raise "GDAL/OGR is required but not found. Install with: brew install gdal (macOS) or apt-get install gdal-bin (Ubuntu)"
    end

    # Check if http gem is available
    begin
      require "http"
    rescue LoadError
      raise "http gem is required but not found. Install with: bundle install"
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
        raise "Failed to download map data (HTTP #{response.code}). Possible issues: map is not publicly accessible, invalid map ID, or network connectivity issues."
      end

      @kml_data = response.body.to_s
      log "Downloaded #{@kml_data.length} bytes of KML data"

      # Basic validation that we got KML content
      unless @kml_data.match?(/<\?xml|<kml/i)
        raise "Downloaded content doesn't appear to be valid KML. Content preview: #{@kml_data[0..200]}..."
      end

      # Save raw KML for debugging
      File.write("tmp/raw_data.kml", @kml_data)
      log "Raw KML saved to tmp/raw_data.kml"
    rescue HTTP::Error => e
      raise "HTTP request failed: #{e.message}. This might be due to network connectivity issues, timeout, or Google Maps service issues."
    end
  end

  def convert_to_geojson
    log "Converting KML to GeoJSON using ogr2ogr..."

    conversion_success = system("ogr2ogr -f GeoJSON tmp/temp_data.geojson tmp/raw_data.kml 2>/dev/null")

    unless conversion_success && File.exist?("tmp/temp_data.geojson")
      raise "Failed to convert KML to GeoJSON. This might happen if the KML file is empty/corrupted or there are GDAL version compatibility issues."
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
      "name" => "#{@layer_name.capitalize} Layer (#{@maps_id})",
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
    puts "   🏷️  Layer: #{@layer_name}"
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
