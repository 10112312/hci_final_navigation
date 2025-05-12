import React, { useEffect, useRef } from 'react';
import { GoogleMap, LoadScript, Marker, Polyline } from '@react-google-maps/api';
import { Location, ChargingStation } from '../services/locationService';

interface RouteMapProps {
    start: Location | null;
    end: Location | null;
    chargingStations: ChargingStation[];
    route: any;
}

const mapContainerStyle = {
    width: '100%',
    height: '400px'
};

const RouteMap: React.FC<RouteMapProps> = ({ start, end, chargingStations, route }) => {
    const mapRef = useRef<google.maps.Map | null>(null);

    useEffect(() => {
        if (mapRef.current && (start || end)) {
            const bounds = new google.maps.LatLngBounds();
            if (start) {
                bounds.extend({ lat: start.lat, lng: start.lng });
            }
            if (end) {
                bounds.extend({ lat: end.lat, lng: end.lng });
            }
            mapRef.current.fitBounds(bounds);
        }
    }, [start, end]);

    const renderRoute = () => {
        if (!route) return null;

        const path = route.legs[0].steps.map((step: any) => ({
            lat: step.start_location.lat,
            lng: step.start_location.lng
        }));

        return (
            <Polyline
                path={path}
                options={{
                    strokeColor: '#3366FF',
                    strokeWeight: 6,
                    strokeOpacity: 0.8
                }}
            />
        );
    };

    return (
        <LoadScript googleMapsApiKey={process.env.REACT_APP_GOOGLE_MAPS_API_KEY!}>
            <GoogleMap
                mapContainerStyle={mapContainerStyle}
                zoom={13}
                onLoad={map => {
                    mapRef.current = map;
                }}
            >
                {start && (
                    <Marker
                        position={{ lat: start.lat, lng: start.lng }}
                        icon={{
                            url: '/images/start-marker.svg',
                            scaledSize: new google.maps.Size(32, 32)
                        }}
                    />
                )}
                {end && (
                    <Marker
                        position={{ lat: end.lat, lng: end.lng }}
                        icon={{
                            url: '/images/end-marker.svg',
                            scaledSize: new google.maps.Size(32, 32)
                        }}
                    />
                )}
                {chargingStations.map(station => (
                    <Marker
                        key={station.id}
                        position={{ lat: station.lat, lng: station.lng }}
                        icon={{
                            url: station.available
                                ? '/images/charging-available.svg'
                                : '/images/charging-unavailable.svg',
                            scaledSize: new google.maps.Size(24, 24)
                        }}
                    />
                ))}
                {renderRoute()}
            </GoogleMap>
        </LoadScript>
    );
};

export default RouteMap; 