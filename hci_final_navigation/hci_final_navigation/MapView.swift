import SwiftUI
import GoogleMaps
import CoreLocation

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var startLocation = ""
    @State private var endLocation = ""
    @State private var routeInfo: RouteInfo? = nil
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var apiErrorMessage: String?
    @State private var startChoices: [PlaceChoice] = []
    @State private var endChoices: [PlaceChoice] = []
    @State private var selectedStart: PlaceChoice?
    @State private var selectedEnd: PlaceChoice?
    @State private var showStartDropdown = false
    @State private var showEndDropdown = false
    private var safeAreaBottom: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.bottom ?? 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                ZStack(alignment: .topLeading) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        TextField("Start Location", text: $startLocation)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button(action: {
                            self.showStartDropdown = false
                            self.startChoices = []
                            if !startLocation.isEmpty {
                                isLoading = true
                                viewModel.searchPlaces(query: startLocation, completion: { choices in
                                    print("searchPlaces completion choices count: \(choices.count)")
                                    DispatchQueue.main.async {
                                        self.isLoading = false
                                        self.startChoices = Array(choices.prefix(5))
                                        print("startChoices after assign: \(self.startChoices)")
                                        self.showStartDropdown = true
                                        viewModel.showSearchMarkers(choices: self.startChoices)
                                    }
                                }, apiErrorHandler: { msg in
                                    self.apiErrorMessage = msg
                                })
                            }
                        }) {
                            Text("Search")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                    }
                    if showStartDropdown {
                        VStack(alignment: .leading, spacing: 0) {
                            if startChoices.isEmpty {
                                Text("No matching places")
                            } else {
                                ForEach(startChoices) { choice in
                                    Button(action: {
                                        self.selectedStart = choice
                                        self.startLocation = choice.description
                                        self.showStartDropdown = false
                                        viewModel.showSearchMarkers(choices: [choice])
                                    }) {
                                        Text(choice.description)
                                            .foregroundColor(.primary)
                                            .padding(8)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .background(Color(.systemGray6))
                                }
                            }
                        }
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                        .padding(.top, 40)
                    }
                }
                .zIndex(2)
                ZStack(alignment: .topLeading) {
                    HStack(spacing: 8) {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.red)
                        TextField("End Location", text: $endLocation)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button(action: {
                            self.showEndDropdown = false
                            self.endChoices = []
                            if !endLocation.isEmpty {
                                isLoading = true
                                viewModel.searchPlaces(query: endLocation, completion: { choices in
                                    print("searchPlaces completion choices count: \(choices.count)")
                                    DispatchQueue.main.async {
                                        self.isLoading = false
                                        self.endChoices = Array(choices.prefix(5))
                                        print("endChoices after assign: \(self.endChoices)")
                                        self.showEndDropdown = true
                                        viewModel.showSearchMarkers(choices: self.endChoices)
                                    }
                                }, apiErrorHandler: { msg in
                                    self.apiErrorMessage = msg
                                })
                            }
                        }) {
                            Text("Search")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                    }
                    if showEndDropdown {
                        VStack(alignment: .leading, spacing: 0) {
                            if endChoices.isEmpty {
                                Text("No matching places")
                            } else {
                                ForEach(endChoices) { choice in
                                    Button(action: {
                                        self.selectedEnd = choice
                                        self.endLocation = choice.description
                                        self.showEndDropdown = false
                                        viewModel.showSearchMarkers(choices: [choice])
                                    }) {
                                        Text(choice.description)
                                            .foregroundColor(.primary)
                                            .padding(8)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .background(Color(.systemGray6))
                                }
                            }
                        }
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                        .padding(.top, 40)
                    }
                }
                .zIndex(1)
                Button(action: {
                    isLoading = true
                    errorMessage = nil
                    let from = selectedStart?.description ?? startLocation
                    let to = selectedEnd?.description ?? endLocation
                    viewModel.getRoute(from: from, to: to) { result in
                        isLoading = false
                        switch result {
                        case .success(let info):
                            self.routeInfo = info
                            viewModel.clearSearchMarkers()
                        case .failure(let err):
                            self.errorMessage = err.localizedDescription
                        }
                    }
                }) {
                    Text("Show Route")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: Color(.systemGray3), radius: 2, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            Spacer().frame(height: 8)
            ZStack(alignment: .topTrailing) {
                GoogleMapView(viewModel: viewModel)
                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                        .padding()
                }
            }
            .frame(minHeight: 220, maxHeight: 340)
            .cornerRadius(16)
            .shadow(color: Color(.systemGray4), radius: 4, x: 0, y: 2)
            .padding(.horizontal, 8)
            .padding(.top, 16)
            Spacer().frame(height: 8)
            if let weather = viewModel.weather {
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "cloud.sun.fill")
                            .foregroundColor(.orange)
                        Text("Weather: \(weather.main), \(weather.description), \(Int(weather.temp))°C")
                            .font(.subheadline)
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
            }
            if (startLocation.isEmpty || endLocation.isEmpty) {
                VStack(alignment: .center, spacing: 8) {
                    Text("Route Info")
                        .font(.headline)
                    Text("Please enter start and end locations")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, max(safeAreaBottom, 16))
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Route Info")
                        .font(.headline)
                    Text("Estimated Distance: \(routeInfo?.distance ?? "-")")
                    Text("Estimated Time: \(routeInfo?.duration ?? "-")")
                    Text("Charging Stops: \(routeInfo?.chargingStops != nil ? String(routeInfo!.chargingStops) : "-")")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, max(safeAreaBottom, 16))
            }
            Spacer(minLength: 0)
        }
        .onAppear {
            viewModel.fetchWeather(lat: 31.2304, lon: 121.4737)
        }
        .alert(isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: Binding<Bool>(
            get: { apiErrorMessage != nil },
            set: { if !$0 { apiErrorMessage = nil } }
        )) {
            Alert(title: Text("API Error"), message: Text(apiErrorMessage ?? ""), dismissButton: .default(Text("OK")))
        }
    }
}

struct PlaceChoice: Identifiable, Equatable {
    let id: String
    let description: String
    init(description: String) {
        self.description = description
        self.id = description
    }
}

struct PlaceChoiceList: View {
    let choices: [PlaceChoice]
    let onSelect: (PlaceChoice) -> Void
    var body: some View {
        NavigationView {
            List(choices) { choice in
                Button(action: { onSelect(choice) }) {
                    Text(choice.description)
                }
            }
            .navigationTitle("Select Location")
        }
    }
}

struct GoogleMapView: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel
    func makeUIView(context: Context) -> GMSMapView {
        let mapView = GMSMapView()
        mapView.camera = GMSCameraPosition.camera(withLatitude: 31.2304, longitude: 121.4737, zoom: 12)
        mapView.delegate = context.coordinator
        viewModel.mapView = mapView
        return mapView
    }
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        viewModel.updateMap()
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapView
        init(_ parent: GoogleMapView) { self.parent = parent }
    }
}

struct RouteInfo {
    let distance: String
    let duration: String
    let chargingStops: Int
}

struct WeatherInfo: Codable {
    let main: String
    let description: String
    let temp: Double
}

class MapViewModel: ObservableObject {
    static let defaultStart = "Shanghai"
    static let defaultEnd = "Beijing"
    let defaultRouteInfo = RouteInfo(distance: "1,215 km", duration: "12h 30m", chargingStops: 2)
    @Published var mapView: GMSMapView?
    @Published var markers: [GMSMarker] = []
    @Published var routePolyline: GMSPolyline?
    @Published var chargingStations: [ChargingStation] = []
    @Published var weather: WeatherInfo?
    private var searchMarkers: [GMSMarker] = []
    
    // Retry logic for network requests
    func fetchWithRetry(url: URL, retries: Int = 2, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            print("fetchWithRetry callback, data: \(data != nil), error: \(error?.localizedDescription ?? "nil")")
            if let data = data {
                print("API Raw Response: \(String(data: data, encoding: .utf8) ?? "nil")")
            }
            if let error = error as NSError?, error.domain == NSURLErrorDomain && error.code == NSURLErrorNetworkConnectionLost, retries > 0 {
                print("Network connection lost, retrying... retries left: \(retries - 1)")
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    self.fetchWithRetry(url: url, retries: retries - 1, completion: completion)
                }
            } else {
                completion(data, error)
            }
        }
        task.resume()
    }
    
    func fetchTeslaChargingStations(accessToken: String, completion: (() -> Void)? = nil) {
        guard let url = URL(string: "https://owner-api.teslamotors.com/api/1/charging-stations") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data, error == nil else { completion?(); return }
            do {
                // 假设返回格式为 { "response": [ { "lat": ..., "lng": ..., "status": "free" }, ... ] }
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let arr = json?["response"] as? [[String: Any]] {
                    let stations = arr.compactMap { dict -> ChargingStation? in
                        guard let lat = dict["lat"] as? Double,
                              let lng = dict["lng"] as? Double,
                              let statusStr = dict["status"] as? String,
                              let status = ChargerStatus(rawValue: statusStr) else { return nil }
                        return ChargingStation(lat: lat, lng: lng, status: status)
                    }
                    DispatchQueue.main.async {
                        self?.chargingStations = stations
                        self?.updateMap()
                        completion?()
                    }
                } else {
                    completion?()
                }
            } catch { completion?() }
        }.resume()
    }
    
    func fetchWeather(lat: Double, lon: Double) {
        let apiKey = Config.openWeatherApiKey
        let urlStr = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        guard let url = URL(string: urlStr) else { return }
        fetchWithRetry(url: url) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let status = json?["cod"] as? Int ?? 200
                if status != 200 { return }
                if let weatherArr = json?["weather"] as? [[String: Any]],
                   let main = weatherArr.first?["main"] as? String,
                   let desc = weatherArr.first?["description"] as? String,
                   let mainObj = json?["main"] as? [String: Any],
                   let temp = mainObj["temp"] as? Double {
                    DispatchQueue.main.async {
                        self?.weather = WeatherInfo(main: main, description: desc, temp: temp)
                    }
                }
            } catch {}
        }
    }
    
    func updateMap() {
        DispatchQueue.main.async {
            guard let mapView = self.mapView else { return }
            mapView.clear()
            // Add charging stations
            for station in self.chargingStations {
                let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: station.lat, longitude: station.lng))
                marker.title = "Charger"
                switch station.status {
                case .free:
                    marker.icon = GMSMarker.markerImage(with: .green)
                    marker.snippet = "Free"
                case .busy:
                    marker.icon = GMSMarker.markerImage(with: .red)
                    marker.snippet = "Busy"
                case .dead:
                    marker.icon = GMSMarker.markerImage(with: .gray)
                    marker.snippet = "Dead"
                }
                marker.map = mapView
            }
            // Add route polyline
            if let polyline = self.routePolyline {
                polyline.map = mapView
            }
        }
    }
    
    func getRoute(from: String, to: String, completion: @escaping (Result<RouteInfo, Error>) -> Void) {
        // 1. Geocode start and end
        geocode(address: from) { [weak self] startResult in
            switch startResult {
            case .success(let startCoord):
                self?.geocode(address: to) { endResult in
                    switch endResult {
                    case .success(let endCoord):
                        self?.fetchRoute(start: startCoord, end: endCoord, completion: completion)
                    case .failure(let err):
                        completion(.failure(err))
                    }
                }
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    func geocode(address: String, completion: @escaping (Result<CLLocationCoordinate2D, Error>) -> Void) {
        let apiKey = Config.googleMapsApiKey
        let urlStr = "https://maps.googleapis.com/maps/api/geocode/json?address=\(address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&key=\(apiKey)"
        guard let url = URL(string: urlStr) else {
            DispatchQueue.main.async {
                completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            }
            return
        }
        fetchWithRetry(url: url) { data, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "No data", code: -1)))
                }
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let status = json?["status"] as? String ?? ""
                if status != "OK" {
                    let msg = json?["error_message"] as? String ?? status
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: msg, code: -2)))
                    }
                    return
                }
                if let results = json?["results"] as? [[String: Any]],
                   let geometry = results.first?["geometry"] as? [String: Any],
                   let location = geometry["location"] as? [String: Any],
                   let lat = location["lat"] as? Double,
                   let lng = location["lng"] as? Double {
                    DispatchQueue.main.async {
                        completion(.success(CLLocationCoordinate2D(latitude: lat, longitude: lng)))
                    }
                } else {
                    let raw = String(data: data, encoding: .utf8) ?? "Unknown"
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "Parse error: \(raw.prefix(200))", code: -4)))
                    }
                }
            } catch {
                let raw = String(data: data, encoding: .utf8) ?? "Unknown"
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "Parse error: \(raw.prefix(200))", code: -4)))
                }
            }
        }
    }
    
    func fetchRoute(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, completion: @escaping (Result<RouteInfo, Error>) -> Void) {
        let apiKey = Config.googleMapsApiKey
        let urlStr = "https://maps.googleapis.com/maps/api/directions/json?origin=\(start.latitude),\(start.longitude)&destination=\(end.latitude),\(end.longitude)&key=\(apiKey)"
        guard let url = URL(string: urlStr) else {
            DispatchQueue.main.async {
                completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            }
            return
        }
        fetchWithRetry(url: url) { [weak self] data, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "No data", code: -1)))
                }
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let status = json?["status"] as? String ?? ""
                if status != "OK" {
                    let msg = json?["error_message"] as? String ?? status
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: msg, code: -2)))
                    }
                    return
                }
                if let routes = json?["routes"] as? [[String: Any]],
                   let route = routes.first,
                   let overviewPolyline = route["overview_polyline"] as? [String: Any],
                   let points = overviewPolyline["points"] as? String,
                   let legs = route["legs"] as? [[String: Any]],
                   let leg = legs.first {
                    let distance = (leg["distance"] as? [String: Any])?["text"] as? String ?? "-"
                    let duration = (leg["duration"] as? [String: Any])?["text"] as? String ?? "-"
                    let distValue = (leg["distance"] as? [String: Any])?["value"] as? Double ?? 0
                    let chargingStops = min(3, Int(distValue / 10000))
                    DispatchQueue.main.async {
                        self?.drawRoute(polyline: points)
                        completion(.success(RouteInfo(distance: distance, duration: duration, chargingStops: chargingStops)))
                    }
                } else {
                    let raw = String(data: data, encoding: .utf8) ?? "Unknown"
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "Parse error: \(raw.prefix(200))", code: -4)))
                    }
                }
            } catch {
                let raw = String(data: data, encoding: .utf8) ?? "Unknown"
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "Parse error: \(raw.prefix(200))", code: -4)))
                }
            }
        }
    }
    
    func drawRoute(polyline: String) {
        DispatchQueue.main.async {
            guard let mapView = self.mapView else { return }
            mapView.clear()
            // 充电桩
            for station in self.chargingStations {
                let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: station.lat, longitude: station.lng))
                marker.title = "Charger"
                switch station.status {
                case .free:
                    marker.icon = GMSMarker.markerImage(with: .green)
                    marker.snippet = "Free"
                case .busy:
                    marker.icon = GMSMarker.markerImage(with: .red)
                    marker.snippet = "Busy"
                case .dead:
                    marker.icon = GMSMarker.markerImage(with: .gray)
                    marker.snippet = "Dead"
                }
                marker.map = mapView
            }
            // 路径
            if let path = GMSPath(fromEncodedPath: polyline) {
                let routePolyline = GMSPolyline(path: path)
                routePolyline.strokeWidth = 5
                routePolyline.strokeColor = .blue
                routePolyline.map = mapView
                self.routePolyline = routePolyline
                // 自动缩放
                let bounds = GMSCoordinateBounds(path: path)
                mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 50))
            }
        }
    }
    
    func searchPlaces(query: String, completion: @escaping ([PlaceChoice]) -> Void, apiErrorHandler: ((String) -> Void)? = nil) {
        let apiKey = Config.googleMapsApiKey
        let urlStr = "https://maps.googleapis.com/maps/api/geocode/json?address=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&key=\(apiKey)"
        print("API Key: \(apiKey)")
        print("Request URL: \(urlStr)")
        guard let url = URL(string: urlStr) else { print("Invalid URL"); completion([]); return }
        fetchWithRetry(url: url) { data, error in
            print("searchPlaces fetchWithRetry returned, data: \(data != nil), error: \(error?.localizedDescription ?? "nil")")
            if let data = data {
                print("searchPlaces got data: \(String(data: data, encoding: .utf8) ?? "nil")")
            }
            guard let data = data, error == nil else {
                print("searchPlaces: No data or error: \(error?.localizedDescription ?? "nil")")
                DispatchQueue.main.async { completion([]) }
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                print("searchPlaces parsed json: \(json ?? [:])")
                let status = json?["status"] as? String ?? ""
                if status != "OK" {
                    let msg = json?["error_message"] as? String ?? status
                    print("searchPlaces: status not OK, msg: \(msg)")
                    DispatchQueue.main.async {
                        apiErrorHandler?(msg)
                        completion([])
                    }
                    return
                }
                let choices: [PlaceChoice] = (json?["results"] as? [[String: Any]] ?? []).compactMap { dict in
                    if let desc = dict["formatted_address"] as? String {
                        return PlaceChoice(description: desc)
                    }
                    return nil
                }
                print("searchPlaces: choices count after parse: \(choices.count)")
                DispatchQueue.main.async { completion(choices) }
            } catch {
                let raw = String(data: data, encoding: .utf8) ?? "Unknown"
                print("searchPlaces: Parse error raw: \(raw)")
                DispatchQueue.main.async {
                    apiErrorHandler?(String(raw.prefix(200)))
                    completion([])
                }
            }
        }
    }
    
    func showSearchMarkers(choices: [PlaceChoice]) {
        guard let mapView = mapView else { return }
        clearSearchMarkers()
        for choice in choices {
            geocode(address: choice.description) { [weak self] result in
                if case .success(let coord) = result {
                    DispatchQueue.main.async {
                        let marker = GMSMarker(position: coord)
                        marker.title = choice.description
                        marker.icon = GMSMarker.markerImage(with: .purple)
                        marker.map = mapView
                        self?.searchMarkers.append(marker)
                    }
                }
            }
        }
    }
    
    func clearSearchMarkers() {
        for marker in searchMarkers { marker.map = nil }
        searchMarkers.removeAll()
    }
}

enum ChargerStatus: String, Codable { case free, busy, dead }
struct ChargingStation: Codable {
    let lat: Double
    let lng: Double
    let status: ChargerStatus
} 
