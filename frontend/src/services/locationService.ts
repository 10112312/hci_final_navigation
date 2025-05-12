import axios from 'axios';

export interface Location {
    id: string;
    name: string;
    address: string;
    lat: number;
    lng: number;
}

export interface ChargingStation {
    id: string;
    name: string;
    address: string;
    lat: number;
    lng: number;
    available: boolean;
    power: number; // 充电功率 (kW)
    type: string; // 充电桩类型
    price: number; // 充电价格 (元/度)
}

// 使用 Google Places API 进行位置搜索
export const searchLocations = async (query: string): Promise<Location[]> => {
    try {
        const response = await axios.get(
            `https://maps.googleapis.com/maps/api/place/autocomplete/json`,
            {
                params: {
                    key: process.env.REACT_APP_GOOGLE_MAPS_API_KEY,
                    input: query,
                    language: 'zh-CN',
                    components: 'country:cn'
                }
            }
        );

        if (response.data.status === 'OK') {
            const predictions = response.data.predictions;
            const places = await Promise.all(
                predictions.map(async (prediction: any) => {
                    const details = await getPlaceDetails(prediction.place_id);
                    return {
                        id: prediction.place_id,
                        name: prediction.structured_formatting.main_text,
                        address: prediction.structured_formatting.secondary_text,
                        lat: details.lat,
                        lng: details.lng
                    };
                })
            );
            return places;
        }
        return [];
    } catch (error) {
        console.error('位置搜索失败:', error);
        return [];
    }
};

// 获取地点详细信息
const getPlaceDetails = async (placeId: string): Promise<{ lat: number; lng: number }> => {
    try {
        const response = await axios.get(
            `https://maps.googleapis.com/maps/api/place/details/json`,
            {
                params: {
                    key: process.env.REACT_APP_GOOGLE_MAPS_API_KEY,
                    place_id: placeId,
                    language: 'zh-CN'
                }
            }
        );

        if (response.data.status === 'OK') {
            const location = response.data.result.geometry.location;
            return {
                lat: location.lat,
                lng: location.lng
            };
        }
        throw new Error('获取地点详情失败');
    } catch (error) {
        console.error('获取地点详情失败:', error);
        throw error;
    }
};

// 获取路线上的充电站
export const getChargingStationsAlongRoute = async (
    start: Location,
    end: Location,
    currentBattery: number,
    maxRange: number
): Promise<ChargingStation[]> => {
    try {
        // 1. 获取路线
        const route = await getRoute(start, end);
        
        // 2. 获取路线附近的充电站
        const stations = await searchChargingStations(route);
        
        // 3. 根据当前电量和续航里程筛选合适的充电站
        return filterChargingStations(stations, route, currentBattery, maxRange);
    } catch (error) {
        console.error('获取充电站失败:', error);
        return [];
    }
};

// 获取路线
const getRoute = async (start: Location, end: Location) => {
    try {
        const response = await axios.get(
            'https://maps.googleapis.com/maps/api/directions/json',
            {
                params: {
                    key: process.env.REACT_APP_GOOGLE_MAPS_API_KEY,
                    origin: `${start.lat},${start.lng}`,
                    destination: `${end.lat},${end.lng}`,
                    language: 'zh-CN',
                    mode: 'driving'
                }
            }
        );

        if (response.data.status === 'OK') {
            return response.data.routes[0];
        }
        throw new Error('获取路线失败');
    } catch (error) {
        console.error('获取路线失败:', error);
        throw error;
    }
};

// 搜索路线附近的充电站
const searchChargingStations = async (route: any): Promise<ChargingStation[]> => {
    try {
        const response = await axios.get(
            'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
            {
                params: {
                    key: process.env.REACT_APP_GOOGLE_MAPS_API_KEY,
                    location: `${route.legs[0].start_location.lat},${route.legs[0].start_location.lng}`,
                    keyword: '充电站',
                    radius: 5000,
                    language: 'zh-CN'
                }
            }
        );

        if (response.data.status === 'OK') {
            return response.data.results.map((place: any) => ({
                id: place.place_id,
                name: place.name,
                address: place.vicinity,
                lat: place.geometry.location.lat,
                lng: place.geometry.location.lng,
                available: true, // 需要实时查询
                power: 60, // 需要从充电站 API 获取
                type: '快充', // 需要从充电站 API 获取
                price: 1.5 // 需要从充电站 API 获取
            }));
        }
        return [];
    } catch (error) {
        console.error('搜索充电站失败:', error);
        return [];
    }
};

// 筛选合适的充电站
const filterChargingStations = (
    stations: ChargingStation[],
    route: any,
    currentBattery: number,
    maxRange: number
): ChargingStation[] => {
    // 计算每个充电站到路线的距离
    const stationsWithDistance = stations.map(station => ({
        ...station,
        distance: calculateDistanceToRoute(station, route)
    }));

    // 根据距离排序
    return stationsWithDistance
        .filter(station => station.distance < 5000) // 距离路线 5 公里以内
        .sort((a, b) => a.distance - b.distance)
        .slice(0, 5); // 返回最近的 5 个充电站
};

// 计算点到路线的距离
const calculateDistanceToRoute = (station: ChargingStation, route: any): number => {
    let minDistance = Infinity;
    
    route.legs[0].steps.forEach((step: any) => {
        const distance = calculateDistance(
            station.lat,
            station.lng,
            step.start_location.lat,
            step.start_location.lng
        );
        minDistance = Math.min(minDistance, distance);
    });

    return minDistance;
};

// 计算两点之间的距离（米）
const calculateDistance = (lat1: number, lng1: number, lat2: number, lng2: number): number => {
    const R = 6371000; // 地球半径（米）
    const dLat = toRad(lat2 - lat1);
    const dLng = toRad(lng2 - lng1);
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
              Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
              Math.sin(dLng/2) * Math.sin(dLng/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
};

const toRad = (value: number): number => {
    return value * Math.PI / 180;
}; 