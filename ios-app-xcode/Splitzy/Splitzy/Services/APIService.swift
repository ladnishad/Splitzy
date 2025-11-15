import Foundation
import SwiftUI

class APIService: ObservableObject {
    static let shared = APIService()

    private let baseURL = "http://localhost:3000/api"
    @Published var authToken: String?

    private init() {
        // Load token from UserDefaults if exists
        self.authToken = UserDefaults.standard.string(forKey: "authToken")
    }

    // MARK: - Helper Methods

    private func createRequest(endpoint: String, method: String, token: String? = nil) -> URLRequest? {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = token ?? authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.message)
            }
            throw APIError.statusCode(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    func saveToken(_ token: String) {
        self.authToken = token
        UserDefaults.standard.set(token, forKey: "authToken")
    }

    func clearToken() {
        self.authToken = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
    }

    // MARK: - Authentication

    func signup(email: String, password: String, name: String) async throws -> AuthResponse {
        guard var request = createRequest(endpoint: "/auth/signup", method: "POST") else {
            throw APIError.invalidURL
        }

        let body: [String: Any] = ["email": email, "password": password, "name": name]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let response: AuthResponse = try await performRequest(request)
        saveToken(response.data.token)
        return response
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        guard var request = createRequest(endpoint: "/auth/login", method: "POST") else {
            throw APIError.invalidURL
        }

        let body: [String: Any] = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let response: AuthResponse = try await performRequest(request)
        saveToken(response.data.token)
        return response
    }

    func getMe() async throws -> UserResponse {
        guard let request = createRequest(endpoint: "/auth/me", method: "GET") else {
            throw APIError.invalidURL
        }

        return try await performRequest(request)
    }

    // MARK: - User Profile

    func getProfile() async throws -> UserResponse {
        guard let request = createRequest(endpoint: "/users/profile", method: "GET") else {
            throw APIError.invalidURL
        }

        return try await performRequest(request)
    }

    func updatePreferences(preferences: UserPreferences) async throws -> UserResponse {
        guard var request = createRequest(endpoint: "/users/preferences", method: "PUT") else {
            throw APIError.invalidURL
        }

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(preferences)

        return try await performRequest(request)
    }

    // MARK: - Friends

    func getFriends() async throws -> UsersResponse {
        guard let request = createRequest(endpoint: "/friends", method: "GET") else {
            throw APIError.invalidURL
        }

        return try await performRequest(request)
    }

    func searchUsers(email: String) async throws -> UsersResponse {
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email
        guard let request = createRequest(endpoint: "/friends/search?email=\(encodedEmail)", method: "GET") else {
            throw APIError.invalidURL
        }

        return try await performRequest(request)
    }

    func addFriend(email: String) async throws -> UsersResponse {
        guard var request = createRequest(endpoint: "/friends", method: "POST") else {
            throw APIError.invalidURL
        }

        let body: [String: Any] = ["friendEmail": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        return try await performRequest(request)
    }

    func removeFriend(friendId: String) async throws -> UsersResponse {
        guard let request = createRequest(endpoint: "/friends/\(friendId)", method: "DELETE") else {
            throw APIError.invalidURL
        }

        return try await performRequest(request)
    }

    // MARK: - Bills

    func getBills() async throws -> BillsResponse {
        guard let request = createRequest(endpoint: "/bills", method: "GET") else {
            throw APIError.invalidURL
        }

        return try await performRequest(request)
    }

    func getBill(id: String) async throws -> BillResponse {
        guard let request = createRequest(endpoint: "/bills/\(id)", method: "GET") else {
            throw APIError.invalidURL
        }

        return try await performRequest(request)
    }

    func createManualBill(restaurantName: String, participants: [String], items: [BillItem]) async throws -> BillResponse {
        guard var request = createRequest(endpoint: "/bills/manual", method: "POST") else {
            throw APIError.invalidURL
        }

        let itemsArray = items.map { item in
            ["name": item.name, "quantity": item.quantity, "cost": item.cost] as [String : Any]
        }

        let body: [String: Any] = [
            "restaurantName": restaurantName,
            "participants": participants,
            "items": itemsArray
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        return try await performRequest(request)
    }

    func uploadBill(image: Data, participants: [String], restaurantName: String, restaurantType: String) async throws -> BillResponse {
        guard let url = URL(string: "\(baseURL)/bills/upload") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()

        // Add image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"bill.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(image)
        body.append("\r\n".data(using: .utf8)!)

        // Add participants
        let participantsJSON = try JSONSerialization.data(withJSONObject: participants)
        if let participantsString = String(data: participantsJSON, encoding: .utf8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"participants\"\r\n\r\n".data(using: .utf8)!)
            body.append(participantsString.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }

        // Add restaurant name
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"restaurantName\"\r\n\r\n".data(using: .utf8)!)
        body.append(restaurantName.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        // Add restaurant type
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"restaurantType\"\r\n\r\n".data(using: .utf8)!)
        body.append(restaurantType.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        return try await performRequest(request)
    }

    func updateBillItems(billId: String, items: [BillItem]) async throws -> BillResponse {
        guard var request = createRequest(endpoint: "/bills/\(billId)/items", method: "PUT") else {
            throw APIError.invalidURL
        }

        let body: [String: Any] = ["items": items.map { item in
            ["name": item.name, "quantity": item.quantity, "cost": item.cost]
        }]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        return try await performRequest(request)
    }

    func deleteBill(id: String) async throws -> MessageResponse {
        guard let request = createRequest(endpoint: "/bills/\(id)", method: "DELETE") else {
            throw APIError.invalidURL
        }

        return try await performRequest(request)
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case statusCode(Int)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .statusCode(let code):
            return "Server returned status code \(code)"
        case .serverError(let message):
            return message
        }
    }
}
