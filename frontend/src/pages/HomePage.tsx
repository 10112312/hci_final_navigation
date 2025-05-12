import React, { useState, useEffect } from 'react';
import SearchBar from '../components/SearchBar';
import RouteMap from '../components/RouteMap';
import { Location, ChargingStation, searchLocations, getChargingStationsAlongRoute } from '../services/locationService';
import { getCurrentLocation } from '../services/geolocationService';

const HomePage: React.FC = () => {
    const [startLocation, setStartLocation] = useState<Location | null>(null);
    const [endLocation, setEndLocation] = useState<Location | null>(null);
    const [chargingStations, setChargingStations] = useState<ChargingStation[]>([]);
    const [route, setRoute] = useState<any>(null);
    const [currentBattery, setCurrentBattery] = useState<number>(80); // 示例：当前电量 80%
    const [maxRange, setMaxRange] = useState<number>(500); // 示例：最大续航 500 公里

    useEffect(() => {
        // 获取当前位置作为起点
        getCurrentLocation().then(location => {
            setStartLocation({
                id: 'current',
                name: '当前位置',
                address: '当前位置',
                lat: location.latitude,
                lng: location.longitude
            });
        });
    }, []);

    useEffect(() => {
        // 当起点和终点都设置后，获取路线和充电站
        if (startLocation && endLocation) {
            getChargingStationsAlongRoute(startLocation, endLocation, currentBattery, maxRange)
                .then(stations => {
                    setChargingStations(stations);
                });
        }
    }, [startLocation, endLocation, currentBattery, maxRange]);

    const handleStartLocationSelect = (location: Location) => {
        setStartLocation(location);
    };

    const handleEndLocationSelect = (location: Location) => {
        setEndLocation(location);
    };

    return (
        <div className="container mx-auto p-4">
            <div className="mb-4">
                <h1 className="text-2xl font-bold mb-4">特斯拉导航</h1>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                            起点
                        </label>
                        <SearchBar
                            onLocationSelect={handleStartLocationSelect}
                            placeholder="输入起点"
                            isStartPoint={true}
                        />
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                            终点
                        </label>
                        <SearchBar
                            onLocationSelect={handleEndLocationSelect}
                            placeholder="输入终点"
                            isStartPoint={false}
                        />
                    </div>
                </div>
            </div>

            <div className="mb-4">
                <RouteMap
                    start={startLocation}
                    end={endLocation}
                    chargingStations={chargingStations}
                    route={route}
                />
            </div>

            {chargingStations.length > 0 && (
                <div className="mt-4">
                    <h2 className="text-xl font-semibold mb-2">推荐充电站</h2>
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                        {chargingStations.map(station => (
                            <div
                                key={station.id}
                                className="border rounded-lg p-4 shadow-sm hover:shadow-md transition-shadow"
                            >
                                <h3 className="font-medium">{station.name}</h3>
                                <p className="text-sm text-gray-600">{station.address}</p>
                                <div className="mt-2 text-sm">
                                    <p>充电功率: {station.power}kW</p>
                                    <p>类型: {station.type}</p>
                                    <p>价格: ¥{station.price}/度</p>
                                    <p className={`mt-1 ${station.available ? 'text-green-600' : 'text-red-600'}`}>
                                        {station.available ? '可用' : '不可用'}
                                    </p>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            )}
        </div>
    );
};

export default HomePage; 