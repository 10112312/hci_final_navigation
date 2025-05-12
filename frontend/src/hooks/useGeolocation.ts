import { useState, useEffect } from 'react';

interface GeolocationState {
    location: {
        latitude: number;
        longitude: number;
    } | null;
    error: string | null;
}

export const useGeolocation = () => {
    const [state, setState] = useState<GeolocationState>({
        location: null,
        error: null
    });

    useEffect(() => {
        if (!navigator.geolocation) {
            setState(prev => ({
                ...prev,
                error: 'Geolocation is not supported by your browser'
            }));
            return;
        }

        const successHandler = (position: GeolocationPosition) => {
            setState({
                location: {
                    latitude: position.coords.latitude,
                    longitude: position.coords.longitude
                },
                error: null
            });
        };

        const errorHandler = (error: GeolocationPositionError) => {
            setState(prev => ({
                ...prev,
                error: error.message
            }));
        };

        navigator.geolocation.getCurrentPosition(successHandler, errorHandler);
    }, []);

    return state;
}; 