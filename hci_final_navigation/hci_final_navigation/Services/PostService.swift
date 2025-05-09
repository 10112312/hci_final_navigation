import Foundation

class PostService: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    func fetchPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
        isLoading = true
        
        let urlString = "\(Config.backendBaseURL)/posts"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(PostError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
            }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(PostError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let posts = try decoder.decode([Post].self, from: data)
                
                DispatchQueue.main.async {
                    self?.posts = posts
                }
                
                completion(.success(posts))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func createPost(_ post: Post, completion: @escaping (Result<Post, Error>) -> Void) {
        let urlString = "\(Config.backendBaseURL)/posts"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(PostError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(post)
            
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(PostError.noData))
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let newPost = try decoder.decode(Post.self, from: data)
                    
                    DispatchQueue.main.async {
                        self?.posts.insert(newPost, at: 0)
                    }
                    
                    completion(.success(newPost))
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    func likePost(_ postId: UUID, completion: @escaping (Result<Post, Error>) -> Void) {
        let urlString = "\(Config.backendBaseURL)/posts/\(postId)/like"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(PostError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(PostError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let updatedPost = try decoder.decode(Post.self, from: data)
                
                DispatchQueue.main.async {
                    if let index = self?.posts.firstIndex(where: { $0.id == postId }) {
                        self?.posts[index] = updatedPost
                    }
                }
                
                completion(.success(updatedPost))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// 错误类型
enum PostError: Error {
    case invalidURL
    case noData
    case unauthorized
    case notFound
    case networkError
} 