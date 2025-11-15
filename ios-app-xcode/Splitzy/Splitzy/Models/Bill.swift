import Foundation

struct Bill: Identifiable, Codable {
    let id: String
    let uploadedBy: User
    let imageUrl: String
    var participants: [User]
    var items: [BillItem]
    var totalAmount: Double
    var status: BillStatus
    var assignmentMode: AssignmentMode
    var itemAssignments: [ItemAssignment]
    var shares: [BillShare]
    var restaurant: Restaurant
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case uploadedBy, imageUrl, participants, items, totalAmount, status
        case assignmentMode, itemAssignments, shares, restaurant, createdAt
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
    case finalized = "finalized"

    var displayName: String {
        switch self {
        case .uploaded: return "Uploaded"
        case .processing: return "Processing"
        case .processed: return "Processed"
        case .split: return "Split"
        case .finalized: return "Finalized"
        }
    }
}

enum AssignmentMode: String, Codable {
    case notSet = "not_set"
    case uploaderAssigns = "uploader_assigns"
    case selfSelect = "self_select"

    var displayName: String {
        switch self {
        case .notSet: return "Not Set"
        case .uploaderAssigns: return "I'll Assign"
        case .selfSelect: return "Let Them Pick"
        }
    }
}

struct ItemAssignment: Identifiable, Codable {
    var id: String?
    let itemId: String
    let participant: User
    let quantity: Int
    let claimedAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case itemId, participant, quantity, claimedAt
    }
}

struct BillShare: Identifiable, Codable {
    var id: String { participant.id }
    let participant: User
    let amount: Double
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
