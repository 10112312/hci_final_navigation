import Foundation
import CoreLocation

struct WeatherInfo: Codable {
    let temperature: Double
    let condition: String
    let humidity: Int
    let windSpeed: Double
    let precipitation: Double
}

class WeatherService {
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func getWeather(for location: CLLocationCoordinate2D) async throws -> WeatherInfo {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(location.latitude)&lon=\(location.longitude)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(WeatherResponse.self, from: data)
        
        return WeatherInfo(
            temperature: response.main.temp,
            condition: response.weather.first?.main ?? "",
            humidity: response.main.humidity,
            windSpeed: response.wind.speed,
            precipitation: response.rain?.oneHour ?? 0
        )
    }
    
    func getTravelAdvice(weather: WeatherInfo) -> String {
        var advice: [String] = []
        
        // 温度建议
        if weather.temperature > 30 {
            advice.append("高温天气，请注意车内温度调节")
        } else if weather.temperature < 5 {
            advice.append("低温天气，电池效率可能降低，建议提前规划充电")
        }
        
        // 降水建议
        if weather.precipitation > 0 {
            advice.append("有降水，路面可能湿滑，请谨慎驾驶")
        }
        
        // 风速建议
        if weather.windSpeed > 20 {
            advice.append("强风天气，可能影响行驶稳定性")
        }
        
        return advice.isEmpty ? "天气适宜出行" : advice.joined(separator: "。")
    }
}

// API 响应模型
private struct WeatherResponse: Codable {
    let weather: [Weather]
    let main: Main
    let wind: Wind
    let rain: Rain?
}

private struct Weather: Codable {
    let main: String
    let description: String
}

private struct Main: Codable {
    let temp: Double
    let humidity: Int
}

private struct Wind: Codable {
    let speed: Double
}

private struct Rain: Codable {
    let oneHour: Double?
    
    enum CodingKeys: String, CodingKey {
        case oneHour = "1h"
    }
} 