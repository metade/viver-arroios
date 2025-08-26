# Data Workflow: Google My Maps Integration

This document explains how to download data from Google My Maps and process it for use in the Jekyll site.

## Overview

The workflow downloads map data from Google My Maps, converts it to GeoJSON format, filters out invalid features, and prepares it for visualization on the MapLibre map.

## Prerequisites

### Software Requirements

1. **GDAL/OGR** - Required for KML to GeoJSON conversion
   ```bash
   # macOS
   brew install gdal

   # Ubuntu/Debian
   sudo apt-get install gdal-bin
   
   # Windows (using conda)
   conda install gdal
   ```

2. **Tippecanoe** - Required for PMTiles generation
   ```bash
   # macOS
   brew install tippecanoe
   
   # Ubuntu/Debian (build from source)
   git clone https://github.com/felt/tippecanoe.git
   cd tippecanoe && make -j && sudo make install
   ```

3. **Ruby** - Already available if you're running Jekyll

4. **HTTP gem** - Required for robust HTTP downloads from Google
   ```bash
   # Install via bundle (recommended)
   bundle install
   
   # Or install directly
   gem install http
   ```

### Google My Maps Setup

1. Create or find your Google My Maps
2. Make sure the map is **publicly accessible**
3. Get the map ID from the sharing URL:
   - URL format: `https://www.google.com/maps/d/viewer?mid=YOUR_MAP_ID`
   - Extract `YOUR_MAP_ID` from the URL

## Usage

The script automatically uses the correct Google My Maps export URL with `forcekml=1` parameter to ensure proper KML format. The workflow supports multiple layers and generates PMTiles for efficient web mapping.

### Method 1: Using Rake Tasks

#### Single Layer (Propostas)
```bash
# Set your Google My Maps ID
export MY_GOOGLE_MAPS_ID="your_map_id_here"

# Download and process the propostas layer
rake download_maps

# Generate PMTiles from all GeoJSON layers
rake generate_pmtiles

# Or run the full workflow (download + PMTiles)
rake build

# Clean up temporary files
rake clean
```

#### Multiple Layers
```bash
# Download the main propostas layer
export MY_GOOGLE_MAPS_ID="your_main_map_id"
rake download_maps

# Download additional layers
LAYER_NAME=comercio MAPS_ID="your_commerce_map_id" rake download_layer
LAYER_NAME=residencial MAPS_ID="your_residential_map_id" rake download_layer

# Generate PMTiles with all layers
rake generate_pmtiles
```

### Method 2: Using the Ruby Class Directly

For integration in other Ruby code:

```ruby
require_relative 'scripts/download_maps'

downloader = GoogleMyMapsDownloader.new(
  maps_id: 'your_map_id_here',
  output: 'tmp/data.geojson',
  verbose: true
)

downloader.download_and_process
puts "Downloaded #{downloader.valid_features.length} features"
```

## Workflow Steps

The complete workflow supports multiple layers and includes data download and PMTiles generation:

### Data Download (`GoogleMyMapsDownloader` class)
1. **Validate Requirements**: Checks for GDAL, HTTP gem, and map ID
2. **Download KML**: Fetches map data using `forcekml=1` parameter
3. **Convert to GeoJSON**: Uses GDAL's `ogr2ogr` for format conversion
4. **Filter Features**: Removes features with invalid or missing coordinates
5. **Validate Geometry**: Ensures all coordinates are within valid ranges
6. **Save Result**: Outputs layer-specific GeoJSON (e.g., `tmp/propostas.geojson`)

### PMTiles Generation (Tippecanoe)
1. **Validate Tippecanoe**: Checks for Tippecanoe installation
2. **Discover Layers**: Finds all GeoJSON files in `tmp/` directory
3. **Generate Tiles**: Converts all GeoJSON files to single PMTiles with multiple layers
4. **Layer Mapping**: Each GeoJSON file becomes a separate layer in PMTiles
5. **Optimize**: Uses appropriate zoom levels and tile optimization
6. **Output**: Creates `tmp/data.pmtiles` with all layers for web mapping

## Data Validation

The script performs several validation checks:

### Coordinate Validation
- **Point**: Must have at least 2 coordinates (longitude, latitude)
- **LineString**: Must have at least 2 points
- **Polygon**: Must have closed rings with at least 4 points
- **Multi-geometries**: Validated recursively

### Geographic Bounds
- Longitude: -180 to 180 degrees
- Latitude: -90 to 90 degrees

### Feature Filtering
Features are excluded if they have:
- Missing or null geometry
- Missing or null coordinates
- Invalid coordinate values
- Malformed geometry structures

## File Structure

```
tmp/
├── propostas.geojson     # Main propostas layer GeoJSON
├── comercio.geojson      # Commerce layer GeoJSON (if downloaded)
├── residencial.geojson   # Residential layer GeoJSON (if downloaded)
├── data.pmtiles          # Combined PMTiles with all layers
├── raw_data.kml          # Original KML from Google (temporary)
└── temp_data.geojson     # Intermediate conversion (temporary)
```

## Output Format

The resulting `tmp/data.geojson` file contains:

```json
{
  "type": "FeatureCollection",
  "name": "Google My Maps Data (map_id)",
  "crs": {
    "type": "name",
    "properties": {
      "name": "urn:ogc:def:crs:OGC:1.3:CRS84"
    }
  },
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [-9.142, 38.736]
      },
      "properties": {
        "Name": "Feature Name",
        "description": "Feature Description"
      }
    }
  ]
}
```

## Troubleshooting

## PMTiles Generation

PMTiles is a modern format for serving map tiles efficiently. The generated PMTiles file can be used with MapLibre GL JS for fast, interactive mapping with multiple layers.

### Multi-Layer PMTiles

The workflow automatically creates a single PMTiles file with multiple layers:
- Each GeoJSON file in `tmp/` becomes a separate layer
- Layer names match the filename (e.g., `propostas.geojson` → `propostas` layer)
- All layers share the same zoom levels and optimization settings

### PMTiles Settings

The Rake task uses these Tippecanoe settings:
- **Layer names**: Derived from GeoJSON filenames
- **Zoom levels**: 0-14 (adjustable based on data density)
- **Optimization**: Drop densest features as needed
- **Extension**: Extend zooms if still dropping features

### Customizing PMTiles

Edit the Rakefile to customize Tippecanoe options:
```ruby
cmd_parts = [
  "tippecanoe",
  "--output=tmp/data.pmtiles",
  "--minimum-zoom=0",
  "--maximum-zoom=16",  # Higher for more detail
  "--drop-densest-as-needed"
]

# Each GeoJSON file becomes a layer
geojson_files.each do |file|
  layer_name = File.basename(file, ".geojson")
  cmd_parts << "--layer=#{layer_name}:#{file}"
end
```

### Layer Management

```bash
# List current layers
ls tmp/*.geojson

# Remove a specific layer
rm tmp/unwanted_layer.geojson

# Regenerate PMTiles with remaining layers
rake generate_pmtiles
```

## Troubleshooting

### Common Issues

1. **Map Not Publicly Accessible (Most Common)**
   - Error: HTTP 403/404 or HTML content instead of KML
   - Solution: In Google My Maps, click "Share" → "Anyone with the link" → "Viewer"

2. **Invalid Map ID**
   - Error: HTTP 404 response
   - Double-check the map ID from your Google My Maps sharing URL
   - Format: `https://www.google.com/maps/d/viewer?mid=YOUR_MAP_ID_HERE`

3. **Empty or No Geographic Data**
   - KML downloaded successfully but contains no features with coordinates
   - Your map exists but has no features with location data

4. **Tippecanoe Not Found**
   ```bash
   # Check if Tippecanoe is installed
   which tippecanoe
   
   # Install Tippecanoe if missing
   brew install tippecanoe  # macOS
   ```

5. **GDAL Not Found**
   ```bash
   # Check if GDAL is installed
   which ogr2ogr
   
   # Install GDAL if missing
   brew install gdal  # macOS
   sudo apt-get install gdal-bin  # Ubuntu
   ```

6. **HTTP Gem Missing**
   ```bash
   # Install the http gem
   bundle install

   # Or install directly
   gem install http
   ```

7. **Connection/Network Issues**
   - Corporate networks may block Google services
   - Try from a different network if possible

8. **PMTiles Generation Fails**
   - Check that GeoJSON file exists and is valid
   - Verify Tippecanoe installation
   - Try with simpler Tippecanoe options first

### Debug Information

The workflow produces several files for debugging:
- `tmp/raw_data.kml` - KML from Google (for inspection if issues occur)
- `tmp/*.geojson` - Processed GeoJSON data for each layer
- `tmp/data.pmtiles` - Final PMTiles with all layers for web mapping
- Verbose output shows download and conversion details for each layer

## Next Steps

After successfully generating PMTiles, you can:

1. **Load on MapLibre map** - Use the PMTiles with MapLibre GL JS
2. **Deploy to web** - Serve PMTiles files for interactive mapping
3. **Customize processing** - Modify Ruby class or Tippecanoe settings
4. **Integrate with Jekyll** - Add PMTiles to your Jekyll site's map

## Environment Variables

| Variable | Description | Required | Usage |
|----------|-------------|----------|-------|
| `MY_GOOGLE_MAPS_ID` | Google My Maps ID for propostas layer | Yes | Main layer download |
| `LAYER_NAME` | Name for additional layer | Yes* | Additional layers only |
| `MAPS_ID` | Google My Maps ID for additional layer | Yes* | Additional layers only |

*Required only when using `rake download_layer`

## Example Map IDs

Google My Maps URLs look like:
```
https://www.google.com/maps/d/viewer?mid=1BvNertbkuieuJHi8kmzKuDy4kbD2TINm4
```

The map ID would be: `1BvNertbkuieuJHi8kmzKuDy4kbD2TINm4`
