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

2. **Ruby** - Already available if you're running Jekyll

3. **HTTP gem** - Required for robust HTTP downloads from Google
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

The script automatically uses the correct Google My Maps export URL with `forcekml=1` parameter to ensure proper KML format.

### Method 1: Using Rake Tasks

Set the environment variable and run the Rake task:

```bash
# Set your Google My Maps ID
export MY_GOOGLE_MAPS_ID="your_map_id_here"

# Download and process the data
rake download_maps

# View statistics about the downloaded data
rake stats

# Clean up temporary files
rake clean
```

### Method 2: Using the Helper Script

The helper script provides more options and verbose output:

```bash
# Basic usage
ruby scripts/download_maps.rb --maps-id your_map_id_here

# With verbose output
ruby scripts/download_maps.rb --maps-id your_map_id_here --verbose

# Custom output file
ruby scripts/download_maps.rb --maps-id your_map_id_here --output custom_data.geojson

# Using environment variable
MY_GOOGLE_MAPS_ID="your_map_id_here" ruby scripts/download_maps.rb

# Show help
ruby scripts/download_maps.rb --help
```

## Workflow Steps

1. **Download KML**: Fetches the map data from Google My Maps in KML format
2. **Convert to GeoJSON**: Uses GDAL's `ogr2ogr` to convert KML to GeoJSON
3. **Filter Features**: Removes features with invalid or missing coordinates
4. **Validate Geometry**: Ensures all coordinates are within valid ranges
5. **Save Result**: Outputs clean GeoJSON to `tmp/data.geojson`

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
├── data.geojson       # Final processed GeoJSON (this is what you want)
├── raw_data.kml       # Original KML from Google (temporary)
└── temp_data.geojson  # Intermediate conversion (temporary)
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

4. **GDAL Not Found**
   ```bash
   # Check if GDAL is installed
   which ogr2ogr

   # Install GDAL if missing
   brew install gdal  # macOS
   sudo apt-get install gdal-bin  # Ubuntu
   ```

5. **HTTP Gem Missing**
   ```bash
   # Install the http gem
   bundle install

   # Or install directly
   gem install http
   ```

6. **Connection/Network Issues**
   - Test connectivity: `ruby scripts/test_http.rb`
   - Corporate networks may block Google services
   - Try from a different network if possible

### Debug Information

The script provides debugging information:
- `tmp/raw_data.kml` - KML from Google (for inspection if issues occur)
- Verbose output shows download and conversion details
- Statistics show feature counts and types

## Next Steps

After successfully downloading the data, you can:

1. **Generate PMTiles** (next step in the workflow)
2. **Visualize on the map** using MapLibre
3. **Analyze the data** using the statistics rake task
4. **Customize processing** by modifying the helper script

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `MY_GOOGLE_MAPS_ID` | Google My Maps ID from sharing URL | Yes |

## Example Map IDs

Google My Maps URLs look like:
```
https://www.google.com/maps/d/viewer?mid=1BvNertbkuieuJHi8kmzKuDy4kbD2TINm4
```

The map ID would be: `1BvNertbkuieuJHi8kmzKuDy4kbD2TINm4`
