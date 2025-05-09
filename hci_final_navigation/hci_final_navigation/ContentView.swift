import SwiftUI
import GoogleMaps
import GooglePlaces

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                MapView()
                    .navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Text("Navigation")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
            }
            .tabItem {
                Image(systemName: "map")
                Text("Navigation")
            }
            .tag(0)
            
            NavigationView {
                CommunityView()
                    .navigationTitle("Community")
            }
            .tabItem {
                Image(systemName: "person.3")
                Text("Community")
            }
            .tag(1)
            
            NavigationView {
                ProfileView()
                    .navigationTitle("Profile")
            }
            .tabItem {
                Image(systemName: "person.circle")
                Text("Profile")
            }
            .tag(2)
        }
    }
}

struct ProfileView: View {
    var body: some View {
        List {
            Section(header: Text("Personal Information")) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Username")
                            .font(.headline)
                        Text("Bio")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Settings")) {
                NavigationLink(destination: Text("Profile Settings")) {
                    Label("Profile Settings", systemImage: "person")
                }
                NavigationLink(destination: Text("Notification Settings")) {
                    Label("Notification Settings", systemImage: "bell")
                }
                NavigationLink(destination: Text("Privacy Settings")) {
                    Label("Privacy Settings", systemImage: "lock")
                }
            }
            
            Section(header: Text("Other")) {
                NavigationLink(destination: Text("About Us")) {
                    Label("About Us", systemImage: "info.circle")
                }
                NavigationLink(destination: Text("Help Center")) {
                    Label("Help Center", systemImage: "questionmark.circle")
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
