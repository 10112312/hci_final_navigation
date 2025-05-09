import SwiftUI
import AuthenticationServices

struct TeslaLoginView: View {
    @State private var authSession: ASWebAuthenticationSession?
    @State private var accessToken: String?
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            Button("Login with Tesla") {
                startTeslaOAuth()
            }
            .padding()
            
            if let token = accessToken {
                Text("Access Token: \(token)")
                    .font(.footnote)
                    .padding()
            }
            if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            }
        }
    }

    func startTeslaOAuth() {
        guard let authURL = getTeslaAuthURL() else { return }
        let callbackScheme = URL(string: Config.teslaRedirectURI)?.scheme ?? "http"
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        authSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: callbackScheme
        ) { callbackURL, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            guard let callbackURL = callbackURL,
                  let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                  let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                self.errorMessage = "No code in callback"
                return
            }
            // 用 code 换取 access token（通过后端中转）
            exchangeCodeForToken(code: code)
        }
        if let window = window {
            authSession?.presentationContextProvider = window as? ASWebAuthenticationPresentationContextProviding
        }
        authSession?.start()
    }

    func getTeslaAuthURL() -> URL? {
        var components = URLComponents(string: Config.teslaAuthURL)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: Config.teslaClientID),
            URLQueryItem(name: "redirect_uri", value: Config.teslaRedirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid email offline_access"),
            URLQueryItem(name: "state", value: UUID().uuidString)
        ]
        return components?.url
    }

    func exchangeCodeForToken(code: String) {
        guard let url = URL(string: Config.backendTokenURL) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let params = ["code": code, "redirect_uri": Config.teslaRedirectURI]
        request.httpBody = try? JSONSerialization.data(withJSONObject: params)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { self.errorMessage = "No data" }
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let token = json?["access_token"] as? String {
                    DispatchQueue.main.async { self.accessToken = token }
                } else {
                    DispatchQueue.main.async { self.errorMessage = "No access token in response" }
                }
            } catch {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
            }
        }.resume()
    }
} 