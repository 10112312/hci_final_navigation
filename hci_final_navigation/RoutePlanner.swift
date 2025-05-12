import Foundation
import CoreLocation
import GoogleMaps

struct RouteSegment {
    let start: CLLocationCoordinate2D
    let end: CLLocationCoordinate2D
    let distance: Double // 米
    let duration: TimeInterval // 秒
    let batteryConsumption: Double // 百分比
}

struct ChargingStop {
    let station: ChargingStation
    let chargingTime: TimeInterval // 秒
    let batteryLevel: Double // 百分比
}

class RoutePlanner {
    private let weatherService: WeatherService
    private let currentBattery: Double
    private let maxRange: Double // 公里
    private let batteryCapacity: Double // 千瓦时
    
    init(weatherService: WeatherService, currentBattery: Double, maxRange: Double, batteryCapacity: Double) {
        self.weatherService = weatherService
        self.currentBattery = currentBattery
        self.maxRange = maxRange
        self.batteryCapacity = batteryCapacity
    }
    
    func planRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, chargingStations: [ChargingStation]) async throws -> (path: GMSPath, stops: [ChargingStop]) {
        // 1. 获取路线
        let route = try await getRoute(from: start, to: end)
        
        // 2. 计算每个路段的电量消耗
        let segments = try await calculateRouteSegments(route: route)
        
        // 3. 规划充电站
        let stops = try await planChargingStops(segments: segments, chargingStations: chargingStations)
        
        return (route, stops)
    }
    
    private func getRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) async throws -> GMSPath {
        let origin = "\(start.latitude),\(start.longitude)"
        let destination = "\(end.latitude),\(end.longitude)"
        
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&key=\(GMSServices.apiKey())"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(DirectionsResponse.self, from: data)
        
        guard let route = response.routes.first,
              let path = GMSPath(fromEncodedPath: route.overview_polyline.points) else {
            throw NSError(domain: "RoutePlanner", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法获取路线"])
        }
        
        return path
    }
    
    private func calculateRouteSegments(route: GMSPath) async throws -> [RouteSegment] {
        var segments: [RouteSegment] = []
        let coordinates = route.coordinates
        
        for i in 0..<coordinates.count-1 {
            let start = coordinates[i]
            let end = coordinates[i+1]
            
            // 计算距离
            let distance = calculateDistance(from: start, to: end)
            
            // 获取天气信息
            let weather = try await weatherService.getWeather(for: start)
            
            // 计算电量消耗
            let batteryConsumption = calculateBatteryConsumption(
                distance: distance,
                weather: weather
            )
            
            // 估算时间
            let duration = estimateDuration(distance: distance, weather: weather)
            
            segments.append(RouteSegment(
                start: start,
                end: end,
                distance: distance,
                duration: duration,
                batteryConsumption: batteryConsumption
            ))
        }
        
        return segments
    }
    
    private func planChargingStops(segments: [RouteSegment], chargingStations: [ChargingStation]) async throws -> [ChargingStop] {
        var stops: [ChargingStop] = []
        var currentBatteryLevel = currentBattery
        
        for segment in segments {
            currentBatteryLevel -= segment.batteryConsumption
            
            // 如果电量低于20%，寻找最近的充电站
            if currentBatteryLevel < 20 {
                if let nearestStation = findNearestChargingStation(
                    to: segment.end,
                    stations: chargingStations,
                    currentBatteryLevel: currentBatteryLevel
                ) {
                    // 计算充电时间
                    let chargingTime = calculateChargingTime(
                        currentLevel: currentBatteryLevel,
                        targetLevel: 80,
                        station: nearestStation
                    )
                    
                    stops.append(ChargingStop(
                        station: nearestStation,
                        chargingTime: chargingTime,
                        batteryLevel: 80
                    ))
                    
                    currentBatteryLevel = 80
                }
            }
        }
        
        return stops
    }
    
    private func calculateDistance(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        return startLocation.distance(from: endLocation)
    }
    
    private func calculateBatteryConsumption(distance: Double, weather: WeatherInfo) -> Double {
        // 基础消耗
        var consumption = distance / 1000 / maxRange * 100
        
        // 天气影响
        if weather.temperature > 30 {
            consumption *= 1.2 // 高温增加20%消耗
        } else if weather.temperature < 5 {
            consumption *= 1.3 // 低温增加30%消耗
        }
        
        if weather.precipitation > 0 {
            consumption *= 1.1 // 降水增加10%消耗
        }
        
        if weather.windSpeed > 20 {
            consumption *= 1.15 // 强风增加15%消耗
        }
        
        return consumption
    }
    
    private func estimateDuration(distance: Double, weather: WeatherInfo) -> TimeInterval {
        let baseSpeed = 60.0 // 基础速度 60km/h
        var speed = baseSpeed
        
        // 天气影响
        if weather.precipitation > 0 {
            speed *= 0.8 // 降水降低20%速度
        }
        
        if weather.windSpeed > 20 {
            speed *= 0.9 // 强风降低10%速度
        }
        
        return (distance / 1000) / speed * 3600 // 转换为秒
    }
    
    private func findNearestChargingStation(to location: CLLocationCoordinate2D, stations: [ChargingStation], currentBatteryLevel: Double) -> ChargingStation? {
        return stations
            .filter { $0.available }
            .min { station1, station2 in
                let distance1 = calculateDistance(from: location, to: station1.location)
                let distance2 = calculateDistance(from: location, to: station2.location)
                return distance1 < distance2
            }
    }
    
    private func calculateChargingTime(currentLevel: Double, targetLevel: Double, station: ChargingStation) -> TimeInterval {
        let power = station.power // 充电功率（千瓦）
        let energyNeeded = (targetLevel - currentLevel) / 100 * batteryCapacity
        return energyNeeded / power * 3600 // 转换为秒
    }
} 