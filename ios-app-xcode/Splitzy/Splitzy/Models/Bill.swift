import Foundation

struct Bill: Identifiable, Codable {
    let id: String
    let uploadedBy: User
    let imageUrl: String
    var participants: [User]
    var items: [BillItem]
    var totalAmount: Double
    var status: BillStatus
    var restaurant: Restaurant
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case uploadedBy, imageUrl, participants, items, totalAmount, status, restaurant, createdAt
    }
}

struct BillItem: Identifiable, Codable {
    var id: String?
    var name: String
    var quantity: Int
    var cost: Double

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, quantity, cost
    }
}

struct Restaurant: Codable {
    var name: String
    var type: RestaurantType

    enum CodingKeys: String, CodingKey {
        case name
        case type
    }
}

enum RestaurantType: String, Codable {
    case restaurant = "restaurant"
    case bar = "bar"

    var displayName: String {
        rawValue.capitalized
    }
}

enum BillStatus: String, Codable {
    case uploaded = "uploaded"
    case processing = "processing"
    case processed = "processed"
    case split = "split"

    var displayName: String {
        switch self {
        case .uploaded: return "Uploaded"
        case .processing: return "Processing"
        case .processed: return "Processed"
        case .split: return "Split"
        }
    }
}

// API Response models
struct BillResponse: Codable {
    let success: Bool
    let data: Bill
}

struct BillsResponse: Codable {
    let success: Bool
    let data: [Bill]
}
