import Foundation

struct SupabaseAuthSession: Codable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
    var userID: String
    var email: String

    var needsRefresh: Bool {
        expiresAt.timeIntervalSinceNow < 300
    }
}

private struct SupabaseAuthUser: Codable {
    var id: String
    var email: String?
}

private struct SupabaseAuthResponse: Codable {
    var accessToken: String?
    var refreshToken: String?
    var expiresIn: Int?
    var user: SupabaseAuthUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }

    func session(fallbackEmail: String) -> SupabaseAuthSession? {
        guard let accessToken,
              let refreshToken,
              let userID = user?.id else {
            return nil
        }

        return SupabaseAuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(expiresIn ?? 3600)),
            userID: userID,
            email: user?.email ?? fallbackEmail
        )
    }
}

enum SupabaseAuthError: LocalizedError {
    case missingConfiguration
    case invalidProjectURL
    case confirmationRequired
    case requestFailed(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Sync ist noch nicht eingerichtet."
        case .invalidProjectURL:
            return "Die Sync-Adresse ist ungueltig."
        case .confirmationRequired:
            return "Registrierung erstellt. Bitte bestaetige deine E-Mail und melde dich dann an."
        case let .requestFailed(status, message):
            return "Auth fehlgeschlagen (\(status)): \(message)"
        }
    }
}

final class SupabaseAuthService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func signUp(email: String, password: String) async throws -> SupabaseAuthSession {
        try ensureConfigured()
        let response: SupabaseAuthResponse = try await request(
            path: "/auth/v1/signup",
            method: "POST",
            body: [
                "email": email,
                "password": password
            ]
        )
        guard let authSession = response.session(fallbackEmail: email) else {
            throw SupabaseAuthError.confirmationRequired
        }
        return authSession
    }

    func signIn(email: String, password: String) async throws -> SupabaseAuthSession {
        try ensureConfigured()
        let response: SupabaseAuthResponse = try await request(
            path: "/auth/v1/token",
            method: "POST",
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            body: [
                "email": email,
                "password": password
            ]
        )
        guard let authSession = response.session(fallbackEmail: email) else {
            throw SupabaseAuthError.requestFailed(200, "Der Login hat keine gueltige Sitzung zurueckgegeben.")
        }
        return authSession
    }

    func refresh(_ session: SupabaseAuthSession) async throws -> SupabaseAuthSession {
        try ensureConfigured()
        let response: SupabaseAuthResponse = try await request(
            path: "/auth/v1/token",
            method: "POST",
            queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")],
            body: [
                "refresh_token": session.refreshToken
            ]
        )
        guard let authSession = response.session(fallbackEmail: session.email) else {
            throw SupabaseAuthError.requestFailed(200, "Der Sync konnte die Anmeldung nicht erneuern.")
        }
        return authSession
    }

    private func request<T: Decodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: [String: String]
    ) async throws -> T {
        var components = try urlComponents(path: path)
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else { throw SupabaseAuthError.invalidProjectURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            throw SupabaseAuthError.requestFailed(http.statusCode, message)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func ensureConfigured() throws {
        guard SupabaseConfig.isConfigured else { throw SupabaseAuthError.missingConfiguration }
    }

    private func urlComponents(path: String) throws -> URLComponents {
        guard let baseURL = URL(string: SupabaseConfig.projectURL),
              let host = baseURL.host else {
            throw SupabaseAuthError.invalidProjectURL
        }

        var components = URLComponents()
        components.scheme = baseURL.scheme ?? "https"
        components.host = host
        components.path = path
        return components
    }
}
