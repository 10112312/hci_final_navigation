import Foundation

class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        let urlString = "\(Config.backendBaseURL)/auth/signin"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let credentials = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: credentials)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(AuthError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let user = try decoder.decode(User.self, from: data)
                
                DispatchQueue.main.async {
                    self?.currentUser = user
                    self?.isAuthenticated = true
                }
                
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func signUp(email: String, password: String, name: String, completion: @escaping (Result<User, Error>) -> Void) {
        let urlString = "\(Config.backendBaseURL)/auth/signup"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let userData = ["email": email, "password": password, "name": name]
        request.httpBody = try? JSONSerialization.data(withJSONObject: userData)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(AuthError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let user = try decoder.decode(User.self, from: data)
                
                DispatchQueue.main.async {
                    self?.currentUser = user
                    self?.isAuthenticated = true
                }
                
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
    }
}

// 错误类型
enum AuthError: Error {
    case invalidURL
    case noData
    case invalidCredentials
    case userExists
    case networkError
}

// 用户模型
struct User: Codable {
    let id: String
    let email: String
    let name: String
    let profileImage: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case profileImage = "profile_image"
        case createdAt = "created_at"
    }
} 