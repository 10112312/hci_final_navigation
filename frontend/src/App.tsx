import React, { useState, useEffect } from 'react';
import Login from './components/Login';
import AnxietyIndex from './components/AnxietyIndex';
import { teslaApi } from './services/api';
import { calculateAnxietyIndex } from './services/anxietyService';

function App() {
    const [isAuthenticated, setIsAuthenticated] = useState(false);
    const [vehicles, setVehicles] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [selectedVehicle, setSelectedVehicle] = useState(null);
    const [anxietyIndex, setAnxietyIndex] = useState(0);

    useEffect(() => {
        const token = localStorage.getItem('token');
        if (token) {
            setIsAuthenticated(true);
            fetchVehicles();
        }
    }, []);

    useEffect(() => {
        if (selectedVehicle) {
            calculateAnxiety();
        }
    }, [selectedVehicle]);

    const handleLoginSuccess = (token: string) => {
        localStorage.setItem('token', token);
        setIsAuthenticated(true);
        fetchVehicles();
    };

    const fetchVehicles = async () => {
        setLoading(true);
        setError('');
        try {
            const data = await teslaApi.getVehicles();
            setVehicles(data);
            if (data.length > 0) {
                setSelectedVehicle(data[0]);
            }
        } catch (err: any) {
            setError(err.response?.data?.detail || '获取车辆信息失败');
            if (err.response?.status === 401) {
                localStorage.removeItem('token');
                setIsAuthenticated(false);
            }
        } finally {
            setLoading(false);
        }
    };

    const calculateAnxiety = async () => {
        if (!selectedVehicle) return;

        try {
            const vehicleData = await teslaApi.getVehicleData(selectedVehicle.id);
            const vehicleState = await teslaApi.getVehicleState(selectedVehicle.id);

            const anxiety = calculateAnxietyIndex({
                batteryLevel: vehicleState.battery_level,
                estimatedRange: vehicleData.estimated_range,
                distanceToDestination: 100, // 这里需要根据实际目的地距离计算
                weatherImpact: 0.2, // 这里需要从天气服务获取
                temperature: 25, // 这里需要从天气服务获取
                elevationChange: 0 // 这里需要从路线服务获取
            });

            setAnxietyIndex(anxiety);
        } catch (err) {
            console.error('计算焦虑指数失败:', err);
        }
    };

    if (!isAuthenticated) {
        return <Login onLoginSuccess={handleLoginSuccess} />;
    }

    return (
        <div className="min-h-screen bg-gray-100">
            <nav className="bg-white shadow-sm">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="flex justify-between h-16">
                        <div className="flex">
                            <div className="flex-shrink-0 flex items-center">
                                <h1 className="text-xl font-bold text-gray-900">
                                    Tesla Navigation
                                </h1>
                            </div>
                        </div>
                        <div className="flex items-center">
                            <button
                                onClick={() => {
                                    localStorage.removeItem('token');
                                    setIsAuthenticated(false);
                                }}
                                className="ml-4 px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-red-600 hover:bg-red-700"
                            >
                                退出登录
                            </button>
                        </div>
                    </div>
                </div>
            </nav>

            <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
                {error && (
                    <div className="mb-4 bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
                        {error}
                    </div>
                )}

                {loading ? (
                    <div className="text-center">加载中...</div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div className="bg-white shadow overflow-hidden sm:rounded-lg">
                            <div className="px-4 py-5 sm:px-6">
                                <h2 className="text-lg leading-6 font-medium text-gray-900">
                                    我的车辆
                                </h2>
                            </div>
                            <div className="border-t border-gray-200">
                                <ul className="divide-y divide-gray-200">
                                    {vehicles.map((vehicle: any) => (
                                        <li
                                            key={vehicle.id}
                                            className="px-4 py-4 sm:px-6 hover:bg-gray-50 cursor-pointer"
                                            onClick={() => setSelectedVehicle(vehicle)}
                                        >
                                            <div className="flex items-center justify-between">
                                                <div className="flex items-center">
                                                    <div className="ml-3">
                                                        <p className="text-sm font-medium text-gray-900">
                                                            {vehicle.display_name}
                                                        </p>
                                                        <p className="text-sm text-gray-500">
                                                            {vehicle.vin}
                                                        </p>
                                                    </div>
                                                </div>
                                                <div className="flex space-x-2">
                                                    <button
                                                        onClick={(e) => {
                                                            e.stopPropagation();
                                                            teslaApi.wakeUpVehicle(vehicle.id);
                                                        }}
                                                        className="inline-flex items-center px-3 py-1 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
                                                    >
                                                        唤醒
                                                    </button>
                                                </div>
                                            </div>
                                        </li>
                                    ))}
                                </ul>
                            </div>
                        </div>

                        {selectedVehicle && (
                            <div className="bg-white shadow overflow-hidden sm:rounded-lg">
                                <div className="px-4 py-5 sm:px-6">
                                    <h2 className="text-lg leading-6 font-medium text-gray-900">
                                        焦虑指数
                                    </h2>
                                </div>
                                <div className="border-t border-gray-200 p-4">
                                    <AnxietyIndex
                                        anxietyLevel={anxietyIndex}
                                        batteryLevel={selectedVehicle.battery_level || 0}
                                        estimatedRange={selectedVehicle.estimated_range || 0}
                                        distanceToDestination={100} // 这里需要根据实际目的地距离计算
                                    />
                                </div>
                            </div>
                        )}
                    </div>
                )}
            </main>
        </div>
    );
}

export default App; 