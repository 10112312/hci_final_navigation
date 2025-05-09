import Foundation
import GoogleMaps
import GooglePlaces

class MapManager: ObservableObject {
    @Published var mapView: GMSMapView?
    private let geocoder = GMSGeocoder()
    
    func getDirections(from startLocation: String, to endLocation: String) {
        // 使用地理编码将地址转换为坐标
        geocoder.geocodeAddressString(startLocation) { [weak self] (startResults, error) in
            guard let self = self,
                  let startResult = startResults?.firstResult() else { return }
            
            self.geocoder.geocodeAddressString(endLocation) { (endResults, error) in
                guard let endResult = endResults?.firstResult() else { return }
                
                // 创建路线请求
                let origin = startResult.coordinate
                let destination = endResult.coordinate
                
                // 使用 Google Maps Directions API 获取路线
                let config = GMSURLSessionConfig()
                let service = GMSDirectionsService(config: config)
                let request = GMSDirectionsRequest()
                request.source = GMSPlace(coordinate: origin)
                request.destination = GMSPlace(coordinate: destination)
                request.travelMode = .driving
                
                service.route(request) { [weak self] (response, error) in
                    guard let self = self,
                          let route = response?.routes.first else { return }
                    
                    DispatchQueue.main.async {
                        self.showRoute(route)
                    }
                }
            }
        }
    }
    
    private func showRoute(_ route: GMSRoute) {
        guard let mapView = mapView else { return }
        
        // 清除现有路线
        mapView.clear()
        
        // 创建路线路径
        let path = GMSPath(fromEncodedPath: route.overviewPolyline.encodedPath)
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 3
        polyline.strokeColor = .blue
        polyline.map = mapView
        
        // 添加起点和终点标记
        if let startLocation = route.legs.first?.startLocation {
            let startMarker = GMSMarker(position: startLocation)
            startMarker.title = "起点"
            startMarker.map = mapView
        }
        
        if let endLocation = route.legs.first?.endLocation {
            let endMarker = GMSMarker(position: endLocation)
            endMarker.title = "终点"
            endMarker.map = mapView
        }
        
        // 调整地图视图以显示整个路线
        let bounds = GMSCoordinateBounds(path: path!)
        mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 50))
    }
} 