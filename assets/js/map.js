// Map initialization and configuration
document.addEventListener('DOMContentLoaded', function() {
  // Initialize the map
  const map = new maplibregl.Map({
    container: 'map',
    style: {
      'version': 8,
      'sources': {
        'carto-light': {
          'type': 'raster',
          'tiles': [
            'https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
            'https://cartodb-basemaps-b.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
            'https://cartodb-basemaps-c.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
            'https://cartodb-basemaps-d.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png'
          ],
          'tileSize': 256,
          'attribution': '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>'
        }
      },
      'layers': [
        {
          'id': 'carto-light-layer',
          'type': 'raster',
          'source': 'carto-light',
          'minzoom': 0,
          'maxzoom': 22
        }
      ]
    },
    center: [-9.142, 38.736], // Lisbon, Portugal coordinates
    zoom: 12
  });

  // Add navigation control (the +/- zoom buttons)
  map.addControl(new maplibregl.NavigationControl(), 'top-right');

  // Add geolocate control
  map.addControl(
    new maplibregl.GeolocateControl({
      positionOptions: {
        enableHighAccuracy: true
      },
      trackUserLocation: true,
      showUserHeading: true
    }), 'top-right'
  );

  // Add scale control
  map.addControl(new maplibregl.ScaleControl({
    maxWidth: 100,
    unit: 'metric'
  }), 'bottom-left');

  // Optional: Add a marker at the center
  // Uncomment the lines below to add a marker
  // new maplibregl.Marker()
  //   .setLngLat([-9.142, 38.736])
  //   .addTo(map);

  // Log when map is loaded
  map.on('load', function() {
    console.log('Map loaded successfully!');
  });

  // Optional: Add click event listener
  map.on('click', function(e) {
    console.log('Map clicked at:', e.lngLat);
  });

  // Expose map to global scope for debugging
  window.mapInstance = map;
});
