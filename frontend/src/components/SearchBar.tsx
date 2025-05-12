import React, { useState, useEffect, useRef } from 'react';
import { useGeolocation } from '../hooks/useGeolocation';
import { searchLocations } from '../services/locationService';

interface SearchBarProps {
    onLocationSelect: (location: Location) => void;
    placeholder: string;
    isStartPoint?: boolean;
}

interface Location {
    id: string;
    name: string;
    address: string;
    lat: number;
    lng: number;
}

const SearchBar: React.FC<SearchBarProps> = ({
    onLocationSelect,
    placeholder,
    isStartPoint = false
}) => {
    const [query, setQuery] = useState('');
    const [suggestions, setSuggestions] = useState<Location[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [showSuggestions, setShowSuggestions] = useState(false);
    const searchRef = useRef<HTMLDivElement>(null);
    const { location: currentLocation, error: locationError } = useGeolocation();

    useEffect(() => {
        // 如果是起始点且有当前位置，自动填充
        if (isStartPoint && currentLocation) {
            setQuery('当前位置');
            onLocationSelect({
                id: 'current',
                name: '当前位置',
                address: '当前位置',
                lat: currentLocation.latitude,
                lng: currentLocation.longitude
            });
        }
    }, [currentLocation, isStartPoint]);

    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (searchRef.current && !searchRef.current.contains(event.target as Node)) {
                setShowSuggestions(false);
            }
        };

        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    const handleSearch = async (value: string) => {
        setQuery(value);
        if (value.length < 2) {
            setSuggestions([]);
            return;
        }

        setIsLoading(true);
        try {
            const results = await searchLocations(value);
            setSuggestions(results);
            setShowSuggestions(true);
        } catch (error) {
            console.error('搜索位置失败:', error);
        } finally {
            setIsLoading(false);
        }
    };

    const handleSelect = (location: Location) => {
        setQuery(location.name);
        setShowSuggestions(false);
        onLocationSelect(location);
    };

    return (
        <div className="relative" ref={searchRef}>
            <div className="relative">
                <input
                    type="text"
                    value={query}
                    onChange={(e) => handleSearch(e.target.value)}
                    placeholder={placeholder}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
                {isLoading && (
                    <div className="absolute right-3 top-2.5">
                        <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-blue-500"></div>
                    </div>
                )}
            </div>

            {showSuggestions && suggestions.length > 0 && (
                <div className="absolute z-10 w-full mt-1 bg-white rounded-lg shadow-lg border border-gray-200">
                    {suggestions.map((location) => (
                        <div
                            key={location.id}
                            onClick={() => handleSelect(location)}
                            className="px-4 py-2 hover:bg-gray-100 cursor-pointer"
                        >
                            <div className="font-medium">{location.name}</div>
                            <div className="text-sm text-gray-500">{location.address}</div>
                        </div>
                    ))}
                </div>
            )}

            {locationError && isStartPoint && (
                <div className="text-red-500 text-sm mt-1">
                    无法获取当前位置，请检查位置权限设置
                </div>
            )}
        </div>
    );
};

export default SearchBar; 