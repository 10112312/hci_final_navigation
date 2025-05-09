import SwiftUI

struct Post: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let author: String
    let date: Date
    var likes: Int
    var comments: Int
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
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct CommunityView: View {
    @State private var searchText = ""
    @State private var posts: [Post] = [
        Post(title: "寻找骑行伙伴", content: "有没有人想一起骑行？周末可以约起来！", author: "骑行爱好者", date: Date(), likes: 12, comments: 5),
        Post(title: "分享一个不错的路线", content: "今天发现了一条很棒的路线，风景特别好...", author: "探索者", date: Date().addingTimeInterval(-86400), likes: 8, comments: 3),
        Post(title: "新手求指导", content: "刚开始骑行，有什么建议吗？", author: "新手", date: Date().addingTimeInterval(-172800), likes: 15, comments: 7)
    ]
    
    var filteredPosts: [Post] {
        if searchText.isEmpty {
            return posts
        } else {
            return posts.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.content.localizedCaseInsensitiveContains(searchText) }
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
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜索帖子", text: $text)
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