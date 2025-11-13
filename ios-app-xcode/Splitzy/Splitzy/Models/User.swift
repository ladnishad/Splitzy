import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let name: String
    var preferences: UserPreferences
    var friends: [User]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email, name, preferences, friends
    }
}

struct UserPreferences: Codable {
    var drinksAlcohol: Bool
    var eatsMeat: Bool
    var meatTypes: [String]

    enum CodingKeys: String, CodingKey {
        case drinksAlcohol = "drinks_alcohol"
        case eatsMeat = "eats_meat"
        case meatTypes = "meat_types"
    }

    init(drinksAlcohol: Bool = false, eatsMeat: Bool = true, meatTypes: [String] = []) {
        self.drinksAlcohol = drinksAlcohol
        self.eatsMeat = eatsMeat
        self.meatTypes = meatTypes
    }
}

struct AuthResponse: Codable {
    let success: Bool
    let data: AuthData
}

struct AuthData: Codable {
    let user: UserData
    let token: String
}

struct UserData: Codable {
    let id: String
    let email: String
    let name: String
    let preferences: UserPreferences
}

// Available meat types
enum MeatType: String, CaseIterable, Identifiable {
    case beef = "beef"
    case chicken = "chicken"
    case pork = "pork"
    case lamb = "lamb"
    case fish = "fish"
    case seafood = "seafood"

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}
