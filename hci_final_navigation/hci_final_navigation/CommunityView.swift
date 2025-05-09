import SwiftUI

struct Post: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    let author: String
    let date: Date
    var likes: Int
    var comments: Int
    var location: String
    var isPrivateCharger: Bool
}

struct PostRow: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(post.title)
                    .font(.headline)
                Spacer()
                Text(post.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(post.content)
                .font(.body)
                .lineLimit(3)
            
            HStack {
                Text(post.author)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Label("\(post.likes)", systemImage: "heart")
                        .font(.caption)
                    
                    Label("\(post.comments)", systemImage: "message")
                        .font(.caption)
                }
            }
            
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                Text(post.location)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if post.isPrivateCharger {
                    Label("Private Charger", systemImage: "house.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct CommunityView: View {
    @State private var searchText = ""
    @State private var showingNewPost = false
    @State private var posts: [Post] = [
        Post(id: UUID(), title: "Private Charger Available", content: "I have a Tesla charger available in my garage. Contact me for details.", author: "John Doe", date: Date(), likes: 12, comments: 5, location: "123 Main St", isPrivateCharger: true),
        Post(id: UUID(), title: "Looking for Charging Station", content: "Need a charging station near Central Park. Any recommendations?", author: "Jane Smith", date: Date().addingTimeInterval(-86400), likes: 8, comments: 3, location: "Central Park", isPrivateCharger: false),
        Post(id: UUID(), title: "Charger Sharing Program", content: "Starting a charger sharing program in our neighborhood. Join us!", author: "Mike Johnson", date: Date().addingTimeInterval(-172800), likes: 15, comments: 7, location: "Downtown", isPrivateCharger: true)
    ]
    
    var filteredPosts: [Post] {
        if searchText.isEmpty {
            return posts
        } else {
            return posts.filter { $0.title.localizedCaseInsensitiveContains(searchText) || 
                                $0.content.localizedCaseInsensitiveContains(searchText) ||
                                $0.location.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack {
            SearchBar(text: $searchText)
            
            List(filteredPosts) { post in
                PostRow(post: post)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .listStyle(.plain)
        }
        .navigationBarItems(trailing: Button(action: {
            showingNewPost = true
        }) {
            Image(systemName: "plus")
        })
        .sheet(isPresented: $showingNewPost) {
            NewPostView(posts: $posts)
        }
    }
}

struct NewPostView: View {
    @Binding var posts: [Post]
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    @State private var content = ""
    @State private var location = ""
    @State private var isPrivateCharger = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Post Details")) {
                    TextField("Title", text: $title)
                    TextEditor(text: $content)
                        .frame(height: 100)
                    TextField("Location", text: $location)
                    Toggle("Private Charger", isOn: $isPrivateCharger)
                }
            }
            .navigationTitle("New Post")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Post") {
                    let newPost = Post(
                        id: UUID(),
                        title: title,
                        content: content,
                        author: "Current User",
                        date: Date(),
                        likes: 0,
                        comments: 0,
                        location: location,
                        isPrivateCharger: isPrivateCharger
                    )
                    posts.insert(newPost, at: 0)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.isEmpty || content.isEmpty || location.isEmpty)
            )
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search posts", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
    }
}

struct CommunityView_Previews: PreviewProvider {
    static var previews: some View {
        CommunityView()
    }
} 