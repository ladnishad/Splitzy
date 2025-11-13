import Foundation

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
}

struct ErrorResponse: Codable {
    let success: Bool
    let message: String
}

struct UserResponse: Codable {
    let success: Bool
    let data: User
}

struct UsersResponse: Codable {
    let success: Bool
    let data: [User]
}

struct MessageResponse: Codable {
    let success: Bool
    let message: String
}
