import Foundation
import CoreLocation
import GoogleMaps

struct ChargingStation: Identifiable {
    let id: String
    let name: String
    let location: CLLocationCoordinate2D
    let address: String
    let available: Bool
    let power: Double // 充电功率（千瓦）
    let type: String // 充电站类型（如：Supercharger、Destination Charger等）
    let price: Double // 充电价格（元/千瓦时）
    let connectors: [Connector] // 充电接口类型
    let rating: Double // 评分
    let reviews: [Review] // 评价
    let amenities: [String] // 设施（如：厕所、休息室等）
    let operatingHours: OperatingHours // 营业时间
}

struct Connector: Codable {
    let type: String // 接口类型（如：Type 2、CCS等）
    let power: Double // 功率（千瓦）
    let available: Bool // 是否可用
}

struct Review: Codable {
    let author: String
    let rating: Int
    let comment: String
    let date: Date
}

struct OperatingHours: Codable {
    let isOpen24Hours: Bool
    let periods: [Period]
    
    struct Period: Codable {
        let open: Time
        let close: Time
        
        struct Time: Codable {
            let hour: Int
            let minute: Int
        }
    }
}

struct RouteInfo {
    let distance: Double // 总距离（米）
    let duration: TimeInterval // 预计时间（秒）
    let batteryConsumption: Double // 预计电量消耗（百分比）
    let chargingStops: [ChargingStop] // 充电站停靠点
    let weatherInfo: [WeatherInfo] // 沿途天气信息
    let travelAdvice: String // 出行建议
}

struct ChargingStop {
    let station: ChargingStation
    let chargingTime: TimeInterval // 充电时间（秒）
    let batteryLevel: Double // 充电后电量（百分比）
    let arrivalTime: Date // 预计到达时间
    let departureTime: Date // 预计离开时间
} 