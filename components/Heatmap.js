import { useState, useCallback, useRef, useEffect } from 'react';
import { GoogleMap, useLoadScript, HeatmapLayer, Marker } from '@react-google-maps/api';

// Define libraries as a static constant outside the component
const GOOGLE_MAPS_LIBRARIES = ['visualization', 'places', 'geometry'];

const mapContainerStyle = {
  width: '100%',
  height: '700px',
};

const center = {
  lat: -33.4489, // Santiago, Chile
  lng: -70.6693,
};

const options = {
  mapTypeControl: true,
  streetViewControl: true,
  fullscreenControl: true,
  clickableIcons: false, // Disable clickable POI icons
  zoomControl: true,
  mapTypeId: 'roadmap',
  styles: [
    { elementType: "geometry", stylers: [{ color: "#242f3e" }] },
    { elementType: "labels.text.stroke", stylers: [{ color: "#242f3e" }] },
    { elementType: "labels.text.fill", stylers: [{ color: "#746855" }] },
    {
      featureType: "administrative.locality",
      elementType: "labels.text.fill",
      stylers: [{ color: "#d59563" }],
    },
    {
      featureType: "poi",
      stylers: [{ visibility: "off" }], // Hide all POIs by default
    },
    {
      featureType: "poi.park",
      elementType: "geometry",
      stylers: [{ color: "#263c3f", visibility: "on" }], // Only show parks
    },
    {
      featureType: "poi.park",
      elementType: "labels.text",
      stylers: [{ visibility: "off" }], // Hide park labels
    },
    {
      featureType: "road",
      elementType: "geometry",
      stylers: [{ color: "#38414e" }],
    },
    {
      featureType: "road",
      elementType: "geometry.stroke",
      stylers: [{ color: "#212a37" }],
    },
    {
      featureType: "road",
      elementType: "labels.text.fill",
      stylers: [{ color: "#9ca5b3" }],
    },
    {
      featureType: "road.highway",
      elementType: "geometry",
      stylers: [{ color: "#746855" }],
    },
    {
      featureType: "road.highway",
      elementType: "geometry.stroke",
      stylers: [{ color: "#1f2835" }],
    },
    {
      featureType: "road.highway",
      elementType: "labels.text.fill",
      stylers: [{ color: "#f3d19c" }],
    },
    {
      featureType: "transit",
      stylers: [{ visibility: "off" }], // Hide transit stations and lines
    },
    {
      featureType: "water",
      elementType: "geometry",
      stylers: [{ color: "#17263c" }],
    },
    {
      featureType: "water",
      elementType: "labels.text",
      stylers: [{ visibility: "off" }], // Hide water labels
    },
  ],
};

const markerStyle = {
  path: window.google?.maps?.SymbolPath?.CIRCLE || 0,
  fillColor: '#4A90E2',
  fillOpacity: 0.9,
  scale: 8,
  strokeColor: '#242f3e',  // Dark background color to match the map
  strokeWeight: 2,
};

const Heatmap = () => {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const mapRef = useRef();
  const markersRef = useRef({});
  const [selectedMarker, setSelectedMarker] = useState(null);

  const createLatLng = useCallback((lat, lng) => {
    if (window.google && window.google.maps) {
      return new window.google.maps.LatLng(parseFloat(lat), parseFloat(lng));
    }
    return {
      lat: () => parseFloat(lat),
      lng: () => parseFloat(lng)
    };
  }, []);

  const { isLoaded, loadError } = useLoadScript({
    googleMapsApiKey: process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY,
    libraries: GOOGLE_MAPS_LIBRARIES,
    version: "weekly"
  });

  const loadHeatmapData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      const response = await fetch('/api/heatmap-data');
      if (!response.ok) {
        throw new Error('Failed to fetch heatmap data');
      }
      
      const heatmapData = await response.json();
      setData(heatmapData);

      if (heatmapData.length > 0 && mapRef.current && window.google) {
        const bounds = new window.google.maps.LatLngBounds();
        heatmapData.forEach(point => {
          if (point.lat && point.lng) {
            bounds.extend(createLatLng(point.lat, point.lng));
          }
        });
        mapRef.current.fitBounds(bounds);
      }
    } catch (error) {
      console.error('Error loading heatmap data:', error);
      setError(error.message);
    } finally {
      setLoading(false);
    }
  }, []);

  const onMapLoad = useCallback((map) => {
    mapRef.current = map;
    loadHeatmapData();
  }, [loadHeatmapData]);

  const handleMarkerClick = useCallback((marker) => {
    setSelectedMarker(marker);
  }, []);

  // Create markers when data changes
  useEffect(() => {
    if (!isLoaded || !mapRef.current || !data.length) return;

    // Clean up existing markers
    Object.values(markersRef.current).forEach(marker => marker.setMap(null));
    markersRef.current = {};

    // Create new markers
    data.forEach((point, index) => {
      const marker = new window.google.maps.Marker({
        position: createLatLng(point.lat, point.lng),
        map: mapRef.current,
        icon: markerStyle,
        title: point.address?.full || '',
      });

      marker.addListener('click', () => handleMarkerClick(point));
      markersRef.current[index] = marker;
    });
  }, [isLoaded, data, handleMarkerClick]);

  return (
    <div className="w-full">
      <div className="flex justify-between items-center mb-4">
        <button
          onClick={loadHeatmapData}
          className="px-3 py-1 text-sm bg-blue-500 text-white rounded hover:bg-blue-600 transition-colors disabled:opacity-50"
          disabled={loading}
        >
          {loading ? 'Refreshing...' : 'Refresh Map'}
        </button>
      </div>
      
      {loadError ? (
        <div className="bg-red-50 border border-red-200 text-red-600 p-4 rounded-lg mb-4">
          Error loading Google Maps: {loadError.message}
        </div>
      ) : !isLoaded ? (
        <div className="relative rounded-lg overflow-hidden" style={mapContainerStyle}>
          <div className="absolute inset-0 bg-gray-100 flex items-center justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
          </div>
        </div>
      ) : error ? (
        <div className="bg-red-50 border border-red-200 text-red-600 p-4 rounded-lg mb-4">
          {error}
        </div>
      ) : (
        <div className="relative rounded-lg overflow-hidden">
          <GoogleMap
            mapContainerStyle={mapContainerStyle}
            zoom={12}
            center={center}
            options={options}
            onLoad={onMapLoad}
          >
            {data.map((point, index) => (
              <Marker
                key={index}
                position={createLatLng(point.lat, point.lng)}
                onClick={() => handleMarkerClick(point)}
                icon={markerStyle}
              />
            ))}
            <HeatmapLayer
              data={data
                .filter(point => point.lat && point.lng)
                .map(point => ({
                  location: createLatLng(point.lat, point.lng),
                  weight: point.intensity || 1
                }))}
              options={{
                radius: 20,
                opacity: 0.6,
                gradient: [
                  'rgba(0, 255, 255, 0)',
                  'rgba(0, 255, 255, 1)',
                  'rgba(0, 191, 255, 1)',
                  'rgba(0, 127, 255, 1)',
                  'rgba(0, 63, 255, 1)',
                  'rgba(0, 0, 255, 1)',
                  'rgba(0, 0, 223, 1)',
                  'rgba(0, 0, 191, 1)',
                  'rgba(0, 0, 159, 1)',
                  'rgba(0, 0, 127, 1)',
                  'rgba(63, 0, 91, 1)',
                  'rgba(127, 0, 63, 1)',
                  'rgba(191, 0, 31, 1)',
                  'rgba(255, 0, 0, 1)'
                ]
              }}
            />
            {selectedMarker && (
              <div className="absolute top-4 left-4 bg-white p-4 rounded-lg shadow-lg z-10 max-w-md">
                <h3 className="font-semibold text-lg">{selectedMarker.name || 'Unknown'}</h3>
                <p className="text-sm mt-2 text-gray-600">{selectedMarker.address?.full}</p>
                {selectedMarker.address?.contact && (
                  <p className="text-sm mt-1 text-gray-600">Contact: {selectedMarker.address.contact}</p>
                )}
                <p className="text-sm mt-1 text-gray-500">Orders: {selectedMarker.intensity || 1}</p>
                <button
                  onClick={() => setSelectedMarker(null)}
                  className="mt-3 text-sm text-blue-500 hover:text-blue-600"
                >
                  Close
                </button>
              </div>
            )}
          </GoogleMap>
          {loading && (
            <div className="absolute inset-0 bg-white bg-opacity-75 flex items-center justify-center">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default Heatmap;
