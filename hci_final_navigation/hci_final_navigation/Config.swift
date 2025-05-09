import Foundation

struct Config {
    // API Keys
    static let googleMapsApiKey = "AIzaSyDUyaBMHtEylY8CiuRNSabK8yP5GbFULOg"
    static let openWeatherApiKey = "a18ff6e1b48f6febba42da334c0fb0a9"
    static let teslaApiKey = "YOUR_TESLA_API_KEY"
    
    // API Endpoints
    static let teslaChargingStationsEndpoint = "https://api.tesla.com/v1/charging-stations"
    static let openWeatherEndpoint = "https://api.openweathermap.org/data/2.5/weather"
    
    // Backend API
    static let backendBaseURL = "YOUR_BACKEND_API_URL"
    
    static let teslaClientID = "0422ea8e-ace5-424f-9d4e-bb2797e3ff9f"
    static let teslaRedirectURI = "http://localhost:3000/oauth/callback" // 或你的正式回调地址
    static let teslaAuthURL = "https://auth.tesla.com/oauth2/v3/authorize"
    // 你的后端中转 token 地址
    static let backendTokenURL = "https://your-backend.com/api/tesla/token"
} 
