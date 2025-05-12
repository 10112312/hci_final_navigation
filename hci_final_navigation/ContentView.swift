import SwiftUI
import GoogleMaps
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var startLocation: CLLocationCoordinate2D?
    @State private var endLocation: CLLocationCoordinate2D?
    @State private var route: GMSPath?
    @State private var chargingStations: [ChargingStation] = []
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var searchResults: [Place] = []
    @State private var routeInfo: RouteInfo?
    @State private var selectedStation: ChargingStation?
    @State private var showingStationDetail = false
    @State private var currentBattery = 80.0 // 当前电量百分比
    @State private var maxRange = 500.0 // 最大续航里程（公里）
    @State private var batteryCapacity = 75.0 // 电池容量（千瓦时）
    
    private let weatherService = WeatherService(apiKey: "YOUR_OPENWEATHER_API_KEY")
    private var routePlanner: RoutePlanner {
        RoutePlanner(
            weatherService: weatherService,
            currentBattery: currentBattery,
            maxRange: maxRange,
            batteryCapacity: batteryCapacity
        )
    }
    
    var body: some View {
        ZStack {
            // 地图视图
            MapView(
                startLocation: startLocation,
                endLocation: endLocation,
                route: route,
                chargingStations: chargingStations,
                selectedStation: $selectedStation,
                showingStationDetail: $showingStationDetail
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                // 搜索栏
                SearchBar(
                    text: $searchText,
                    isSearching: $isSearching,
                    searchResults: $searchResults,
                    onLocationSelected: { place in
                        if startLocation == nil {
                            startLocation = CLLocationCoordinate2D(
                                latitude: place.geometry.location.lat,
                                longitude: place.geometry.location.lng
                            )
                        } else {
                            endLocation = CLLocationCoordinate2D(
                                latitude: place.geometry.location.lat,
                                longitude: place.geometry.location.lng
                            )
                            // 计算路线和充电站
                            Task {
                                await calculateRoute()
                            }
                        }
                    }
                )
                .padding()
                
                Spacer()
                
                // 底部控制面板
                if let routeInfo = routeInfo {
                    RouteInfoPanel(
                        routeInfo: routeInfo,
                        onStationSelected: { station in
                            selectedStation = station
                            showingStationDetail = true
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showingStationDetail) {
            if let station = selectedStation {
                ChargingStationDetailView(station: station)
            }
        }
        .onAppear {
            // 获取当前位置
            if let location = locationManager.location {
                startLocation = location.coordinate
            }
        }
    }
    
    private func calculateRoute() async {
        guard let start = startLocation, let end = endLocation else { return }
        
        do {
            let (path, stops) = try await routePlanner.planRoute(
                from: start,
                to: end,
                chargingStations: chargingStations
            )
            
            // 获取天气信息
            let startWeather = try await weatherService.getWeather(for: start)
            let endWeather = try await weatherService.getWeather(for: end)
            
            // 计算总距离和时间
            let totalDistance = path.coordinates.enumerated().reduce(0.0) { sum, pair in
                if pair.offset == 0 { return 0 }
                let prev = path.coordinates[pair.offset - 1]
                return sum + calculateDistance(from: prev, to: pair.element)
            }
            
            let totalDuration = stops.reduce(0.0) { sum, stop in
                sum + stop.chargingTime
            }
            
            // 计算总电量消耗
            let totalBatteryConsumption = stops.reduce(0.0) { sum, stop in
                sum + (stop.batteryLevel - currentBattery)
            }
            
            // 生成出行建议
            let travelAdvice = weatherService.getTravelAdvice(weather: startWeather)
            
            // 更新路线信息
            routeInfo = RouteInfo(
                distance: totalDistance,
                duration: totalDuration,
                batteryConsumption: totalBatteryConsumption,
                chargingStops: stops,
                weatherInfo: [startWeather, endWeather],
                travelAdvice: travelAdvice
            )
            
            // 更新地图
            route = path
            chargingStations = stops.map { $0.station }
            
        } catch {
            print("Error calculating route: \(error)")
        }
    }
    
    private func calculateDistance(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        return startLocation.distance(from: endLocation)
    }
}

// 位置管理器
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
}

// 数据模型
struct Place: Codable {
    let place_id: String
    let name: String
    let geometry: Geometry
    let vicinity: String
}

struct Geometry: Codable {
    let location: Location
}

struct Location: Codable {
    let lat: Double
    let lng: Double
}

struct ChargingStation: Identifiable {
    let id: String
    let name: String
    let location: CLLocationCoordinate2D
    let address: String
    let available: Bool
}

struct DirectionsResponse: Codable {
    let routes: [Route]
}

struct Route: Codable {
    let overview_polyline: Polyline
}

struct Polyline: Codable {
    let points: String
}

struct PlacesResponse: Codable {
    let predictions: [Prediction]
}

struct Prediction: Codable {
    let place_id: String
    let structured_formatting: StructuredFormatting
}

struct StructuredFormatting: Codable {
    let main_text: String
    let secondary_text: String
}

struct PlaceDetailsResponse: Codable {
    let result: Place?
}

// 搜索栏视图
struct SearchBar: View {
    @Binding var text: String
    @Binding var isSearching: Bool
    @Binding var searchResults: [Place]
    let onLocationSelected: (Place) -> Void
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search location...", text: $text)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onChange(of: text) { newValue in
                        searchLocations(query: newValue)
                    }
                
                if isSearching {
                    ProgressView()
                        .padding(.horizontal)
                }
            }
            
            if !searchResults.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach(searchResults, id: \.place_id) { place in
                            Button(action: {
                                getPlaceDetails(placeId: place.place_id) { detailedPlace in
                                    onLocationSelected(detailedPlace)
                                    text = ""
                                    searchResults = []
                                }
                            }) {
                                VStack(alignment: .leading) {
                                    Text(place.name)
                                        .font(.headline)
                                    Text(place.vicinity)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 4)
            }
        }
    }
    
    private func searchLocations(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        let urlString = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&key=\(GMSServices.apiKey())"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            
            do {
                let result = try JSONDecoder().decode(PlacesResponse.self, from: data)
                DispatchQueue.main.async {
                    self.searchResults = result.predictions.map { prediction in
                        Place(
                            place_id: prediction.place_id,
                            name: prediction.structured_formatting.main_text,
                            geometry: Geometry(location: Location(lat: 0, lng: 0)),
                            vicinity: prediction.structured_formatting.secondary_text
                        )
                    }
                    self.isSearching = false
                }
            } catch {
                print("Error decoding search results: \(error)")
                DispatchQueue.main.async {
                    self.isSearching = false
                }
            }
        }.resume()
    }
    
    private func getPlaceDetails(placeId: String, completion: @escaping (Place) -> Void) {
        let urlString = "https://maps.googleapis.com/maps/api/place/details/json?place_id=\(placeId)&key=\(GMSServices.apiKey())"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            
            do {
                let result = try JSONDecoder().decode(PlaceDetailsResponse.self, from: data)
                if let place = result.result {
                    DispatchQueue.main.async {
                        completion(place)
                    }
                }
            } catch {
                print("Error decoding place details: \(error)")
            }
        }.resume()
    }
}

// 地图视图
struct MapView: UIViewRepresentable {
    let startLocation: CLLocationCoordinate2D?
    let endLocation: CLLocationCoordinate2D?
    let route: GMSPath?
    let chargingStations: [ChargingStation]
    @Binding var selectedStation: ChargingStation?
    @Binding var showingStationDetail: Bool
    
    func makeUIView(context: Context) -> GMSMapView {
        let mapView = GMSMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        mapView.clear()
        
        // 添加起点标记
        if let start = startLocation {
            let startMarker = GMSMarker(position: start)
            startMarker.icon = UIImage(named: "start-marker")
            startMarker.map = mapView
        }
        
        // 添加终点标记
        if let end = endLocation {
            let endMarker = GMSMarker(position: end)
            endMarker.icon = UIImage(named: "end-marker")
            endMarker.map = mapView
        }
        
        // 绘制路线
        if let route = route {
            let polyline = GMSPolyline(path: route)
            polyline.strokeWidth = 4
            polyline.strokeColor = .blue
            polyline.map = mapView
            
            // 调整地图视野以显示整个路线
            let bounds = GMSCoordinateBounds(path: route)
            mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 50))
        }
        
        // 添加充电站标记
        for station in chargingStations {
            let marker = GMSMarker(position: station.location)
            marker.icon = UIImage(named: station.available ? "charging-available" : "charging-unavailable")
            marker.title = station.name
            marker.snippet = station.address
            marker.map = mapView
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            if let station = parent.chargingStations.first(where: { $0.location == marker.position }) {
                parent.selectedStation = station
                parent.showingStationDetail = true
            }
            return true
        }
    }
}

// 充电站详情视图
struct ChargingStationDetailView: View {
    let station: ChargingStation
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 标题
                Text(station.name)
                    .font(.title)
                    .bold()
                
                // 地址
                Text(station.address)
                    .foregroundColor(.gray)
                
                // 状态
                HStack {
                    Image(systemName: station.available ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(station.available ? .green : .red)
                    Text(station.available ? "可用" : "不可用")
                }
                
                // 充电信息
                VStack(alignment: .leading, spacing: 8) {
                    Text("充电信息")
                        .font(.headline)
                    
                    HStack {
                        Text("功率：")
                        Text("\(Int(station.power))kW")
                    }
                    
                    HStack {
                        Text("价格：")
                        Text("¥\(String(format: "%.2f", station.price))/kWh")
                    }
                    
                    Text("接口类型：")
                    ForEach(station.connectors, id: \.type) { connector in
                        HStack {
                            Text(connector.type)
                            Text("(\(Int(connector.power))kW)")
                            if connector.available {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                // 设施
                if !station.amenities.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("设施")
                            .font(.headline)
                        
                        ForEach(station.amenities, id: \.self) { amenity in
                            Text("• \(amenity)")
                        }
                    }
                }
                
                // 营业时间
                VStack(alignment: .leading, spacing: 8) {
                    Text("营业时间")
                        .font(.headline)
                    
                    if station.operatingHours.isOpen24Hours {
                        Text("24小时营业")
                    } else {
                        ForEach(station.operatingHours.periods, id: \.open.hour) { period in
                            Text("\(formatTime(period.open)) - \(formatTime(period.close))")
                        }
                    }
                }
                
                // 评价
                if !station.reviews.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("评价")
                            .font(.headline)
                        
                        ForEach(station.reviews, id: \.date) { review in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(review.author)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(review.rating)星")
                                }
                                Text(review.comment)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func formatTime(_ time: OperatingHours.Period.Time) -> String {
        String(format: "%02d:%02d", time.hour, time.minute)
    }
}

// 路线信息面板
struct RouteInfoPanel: View {
    let routeInfo: RouteInfo
    let onStationSelected: (ChargingStation) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 基本信息
            HStack {
                VStack(alignment: .leading) {
                    Text("总距离：\(formatDistance(routeInfo.distance))")
                    Text("预计时间：\(formatDuration(routeInfo.duration))")
                    Text("电量消耗：\(String(format: "%.1f", routeInfo.batteryConsumption))%")
                }
                Spacer()
            }
            
            // 天气信息
            if let startWeather = routeInfo.weatherInfo.first {
                HStack {
                    Text("起点天气：\(startWeather.condition)")
                    Text("\(Int(startWeather.temperature))°C")
                }
            }
            
            // 出行建议
            Text(routeInfo.travelAdvice)
                .foregroundColor(.blue)
            
            // 充电站列表
            if !routeInfo.chargingStops.isEmpty {
                Text("充电站")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(routeInfo.chargingStops, id: \.station.id) { stop in
                            ChargingStopCard(stop: stop) {
                                onStationSelected(stop.station)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 8)
    }
    
    private func formatDistance(_ meters: Double) -> String {
        let kilometers = meters / 1000
        return String(format: "%.1f公里", kilometers)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60
        return "\(hours)小时\(minutes)分钟"
    }
}

// 充电站卡片
struct ChargingStopCard: View {
    let stop: ChargingStop
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(stop.station.name)
                    .font(.headline)
                
                Text(stop.station.address)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "battery.100")
                    Text("充电至\(Int(stop.batteryLevel))%")
                }
                
                Text("充电时间：\(formatDuration(stop.chargingTime))")
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60
        return "\(hours)小时\(minutes)分钟"
    }
} 