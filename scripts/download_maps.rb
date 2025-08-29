#!/usr/bin/env ruby

require "http"
require "json"
require "uri"
require "digest"

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
    @downloaded_images = {}
    @images_dir = "assets/data/images"
  end

  def download_and_process
    validate_requirements
    download_kml
    convert_to_geojson
    filter_features
    download_images
    write_final_geojson
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

    # Ensure images directory exists
    Dir.mkdir(@images_dir) unless Dir.exist?(@images_dir)
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
  end

  def download_images
    log "Processing images from gx_media_links..."

    image_count = 0

    @valid_features.each_with_index do |feature, index|
      properties = feature["properties"]
      next unless properties && properties["gx_media_links"]

      media_links = properties["gx_media_links"].to_s.strip
      next if media_links.empty?

      # Handle multiple URLs separated by whitespace or commas
      urls = media_links.split(/[\s,]+/).reject(&:empty?)
      downloaded_urls = []
      urls.each do |url|
        local_path = download_single_image(url, index)
        if local_path
          downloaded_urls << local_path
          image_count += 1
        end
      rescue => e
        log "Failed to download image #{url}: #{e.message}"
      end

      # Update the feature properties with local paths
      if downloaded_urls.any?
        properties["gx_media_links"] = downloaded_urls.join(" ")
      else
        # Remove the property if no images were downloaded
        properties.delete("gx_media_links")
      end
    end

    log "Downloaded #{image_count} images to #{@images_dir}/"
  end

  def download_single_image(url, feature_index)
    return nil unless url.match?(/^https?:\/\//)

    # Create a unique filename based on URL hash and feature index
    url_hash = Digest::MD5.hexdigest(url)[0..8]
    extension = extract_file_extension(url)
    filename = "#{@layer_name}_#{feature_index}_#{url_hash}#{extension}"
    local_path = File.join(@images_dir, filename)
    relative_path = "./#{local_path}"

    # Skip if already downloaded
    if @downloaded_images[url]
      return @downloaded_images[url]
    end

    # Skip if file already exists
    if File.exist?(local_path)
      log "Image already exists: #{filename}"
      @downloaded_images[url] = relative_path
      return relative_path
    end

    log "Downloading image: #{url} -> #{filename}"

    response = HTTP.timeout(30)
      .follow(max_hops: 3)
      .headers(
        "User-Agent" => "Mozilla/5.0 (compatible; Jekyll Map Downloader)",
        "Accept" => "image/*,*/*"
      )
      .get(url)

    if response.code == 200
      # Validate it's actually an image
      content_type = response.headers["Content-Type"].to_s
      unless content_type.start_with?("image/")
        log "Warning: #{url} doesn't appear to be an image (Content-Type: #{content_type})"
      end

      # Convert response body to string for file writing
      body_content = response.body.to_s
      File.write(local_path, body_content)
      @downloaded_images[url] = relative_path
      log "Successfully downloaded: #{filename} (#{format_file_size(body_content.length)})"
      relative_path
    else
      log "Failed to download #{url}: HTTP #{response.code}"
      nil
    end
  rescue => e
    log "Error downloading #{url}: #{e.message}"
    nil
  end

  def extract_file_extension(url)
    # Try to get extension from URL path
    uri = URI.parse(url)
    path = uri.path.to_s

    # Common image extensions
    if path.match?(/\.(jpe?g|png|gif|webp|bmp|svg)$/i)
      extension = path.match(/(\.[^.]+)$/)[1].downcase
      return extension
    end

    # Default to .jpg if no extension found
    ".jpg"
  rescue
    ".jpg"
  end

  def write_final_geojson
    log "Writing final GeoJSON file..."

    # Create the final GeoJSON structure
    final_geojson = {
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
    File.write(@output_file, JSON.pretty_generate(final_geojson))
    log "Saved final GeoJSON to #{@output_file}"
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
    puts "   🖼️  Downloaded images: #{@downloaded_images.length}"
    puts "   💾 File size: #{format_file_size(file_size)}"
    puts "   📁 Output: #{@output_file}"
    puts "   🖼️  Images folder: #{@images_dir}/"

    # Show feature type breakdown
    feature_types = @valid_features.group_by { |f| f["geometry"]["type"] }
    feature_types.each do |type, features|
      puts "   └─ #{type}: #{features.length} features"
    end

    # Show features with images
    features_with_images = @valid_features.count { |f| f["properties"] && f["properties"]["gx_media_links"] }
    if features_with_images > 0
      puts "   └─ Features with images: #{features_with_images}"
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
