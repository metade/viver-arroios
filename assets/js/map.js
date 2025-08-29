// Map initialization and configuration
document.addEventListener("DOMContentLoaded", function () {
  // Add PMTiles protocol
  let protocol = new pmtiles.Protocol();
  maplibregl.addProtocol("pmtiles", protocol.tile);

  // Initialize the map
  const map = new maplibregl.Map({
    container: "map",
    style: {
      version: 8,
      sources: {
        "carto-light": {
          type: "raster",
          tiles: [
            "https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
            "https://cartodb-basemaps-b.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
            "https://cartodb-basemaps-c.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
            "https://cartodb-basemaps-d.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
          ],
          tileSize: 256,
          attribution:
            '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
        },
      },
      layers: [
        {
          id: "carto-light-layer",
          type: "raster",
          source: "carto-light",
          minzoom: 0,
          maxzoom: 22,
        },
      ],
    },
    center: [-9.13628, 38.72614], // Arroios center coordinates
    zoom: 14,
  });

  // Add navigation control (the +/- zoom buttons)
  map.addControl(new maplibregl.NavigationControl(), "top-right");

  // Add geolocate control
  map.addControl(
    new maplibregl.GeolocateControl({
      positionOptions: {
        enableHighAccuracy: true,
      },
      trackUserLocation: true,
      showUserHeading: true,
    }),
    "top-right",
  );

  // Add scale control
  map.addControl(
    new maplibregl.ScaleControl({
      maxWidth: 100,
      unit: "metric",
    }),
    "bottom-left",
  );

  // Optional: Add a marker at the center
  // Uncomment the lines below to add a marker
  // new maplibregl.Marker()
  //   .setLngLat([-9.142, 38.736])
  //   .addTo(map);

  // Log when map is loaded
  map.on("load", function () {
    console.log("Map loaded successfully!");

    // Load PMTiles data and add propostas layer
    loadPropostasLayer();
  });

  // Optional: Add click event listener
  map.on("click", function (e) {
    console.log("Map clicked at:", e.lngLat);
  });

  // Function to load propostas layer from PMTiles
  function loadPropostasLayer() {
    // Add PMTiles source
    map.addSource("pmtiles-source", {
      type: "vector",
      url: "pmtiles://./assets/data/data.pmtiles",
    });

    // Add Arroios border outline
    map.addLayer({
      id: "arroios-border-outline",
      type: "line",
      source: "pmtiles-source",
      "source-layer": "arroios",
      paint: {
        "line-color": "#A9A9A9",
        "line-width": 3,
        "line-opacity": 0.8,
      },
    });

    // Auto-focus map on Arroios border when data loads
    map.on("sourcedata", function (e) {
      if (e.sourceId === "pmtiles-source" && e.isSourceLoaded) {
        const arroiosFeatures = map.querySourceFeatures("pmtiles-source", {
          sourceLayer: "arroios",
        });

        if (arroiosFeatures.length > 0) {
          // Get Arroios bounds and fit map to them
          const bounds = new maplibregl.LngLatBounds();
          arroiosFeatures[0].geometry.coordinates[0].forEach((coord) => {
            bounds.extend(coord);
          });

          // Fit map to Arroios bounds with padding
          map.fitBounds(bounds, {
            padding: 50,
            maxZoom: 15,
            duration: 1500,
          });
        }
      }
    });

    // Add propostas layer as circles (markers)
    map.addLayer({
      id: "propostas-markers",
      type: "circle",
      source: "pmtiles-source",
      "source-layer": "propostas",
      paint: {
        "circle-radius": 8,
        "circle-color": "#3b82f6",
        "circle-stroke-color": "#ffffff",
        "circle-stroke-width": 2,
        "circle-opacity": 0.8,
      },
    });

    // Add hover effect
    map.on("mouseenter", "propostas-markers", function () {
      map.getCanvas().style.cursor = "pointer";
    });

    map.on("mouseleave", "propostas-markers", function () {
      map.getCanvas().style.cursor = "";
    });

    // Add click handler for propostas markers
    map.on("click", "propostas-markers", function (e) {
      const properties = e.features[0].properties;

      // Remove previous selection styling
      if (map.getLayer("propostas-markers-selected")) {
        map.removeLayer("propostas-markers-selected");
        map.removeSource("propostas-markers-selected");
      }

      // Highlight selected marker
      map.addSource("propostas-markers-selected", {
        type: "geojson",
        data: {
          type: "FeatureCollection",
          features: [e.features[0]],
        },
      });

      map.addLayer({
        id: "propostas-markers-selected",
        type: "circle",
        source: "propostas-markers-selected",
        paint: {
          "circle-radius": 12,
          "circle-color": "#dc3545",
          "circle-stroke-color": "#ffffff",
          "circle-stroke-width": 3,
          "circle-opacity": 0.9,
        },
      });

      // Create panel content
      let panelContent = "";

      // Add all properties to the panel
      Object.keys(properties).forEach((key) => {
        if (
          properties[key] !== null &&
          properties[key] !== undefined &&
          properties[key] !== ""
        ) {
          panelContent += `
            <div class="panel-item">
              <div class="panel-label">${key}</div>
              <div class="panel-value">${properties[key]}</div>
            </div>
          `;
        }
      });

      // Update panel content
      document.getElementById("panelContent").innerHTML = panelContent;

      // Show the offcanvas panel
      const panel = new bootstrap.Offcanvas(
        document.getElementById("detailsPanel"),
      );
      panel.show();
    });

    console.log("Propostas layer loaded successfully!");
  }

  // Expose map to global scope for debugging
  window.mapInstance = map;
});
