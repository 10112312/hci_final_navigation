import SwiftUI
import GoogleMaps
import GooglePlaces

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                GoogleMapView()
                    .navigationTitle("导航")
            }
            .tabItem {
                Image(systemName: "map")
                Text("导航")
            }
            .tag(0)
            
            NavigationView {
                CommunityView()
                    .navigationTitle("社区")
            }
            .tabItem {
                Image(systemName: "person.3")
                Text("社区")
            }
            .tag(1)
            
            NavigationView {
                ProfileView()
                    .navigationTitle("我的")
            }
            .tabItem {
                Image(systemName: "person.circle")
                Text("我的")
            }
            .tag(2)
        }
    }
}

struct GoogleMapView: UIViewRepresentable {
    @StateObject private var mapManager = MapManager()
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: 31.2304, longitude: 121.4737, zoom: 12)
        let mapView = GMSMapView(frame: .zero, camera: camera)
        mapManager.mapView = mapView
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {}
}

struct ProfileView: View {
    var body: some View {
        List {
            Section(header: Text("个人信息")) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("用户名")
                            .font(.headline)
                        Text("个人简介")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("设置")) {
                NavigationLink(destination: Text("个人资料")) {
                    Label("个人资料", systemImage: "person")
                }
                NavigationLink(destination: Text("通知设置")) {
                    Label("通知设置", systemImage: "bell")
                }
                NavigationLink(destination: Text("隐私设置")) {
                    Label("隐私设置", systemImage: "lock")
                }
            }
            
            Section(header: Text("其他")) {
                NavigationLink(destination: Text("关于我们")) {
                    Label("关于我们", systemImage: "info.circle")
                }
                NavigationLink(destination: Text("帮助中心")) {
                    Label("帮助中心", systemImage: "questionmark.circle")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 