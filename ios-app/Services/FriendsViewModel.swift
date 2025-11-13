import Foundation
import SwiftUI

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [User] = []
    @Published var searchResults: [User] = []
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func loadFriends() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiService.getFriends()
            self.friends = response.data
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func searchUsers(email: String) async {
        guard !email.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        do {
            let response = try await apiService.searchUsers(email: email)
            self.searchResults = response.data
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isSearching = false
    }

    func addFriend(email: String) async {
        do {
            let response = try await apiService.addFriend(email: email)
            self.friends = response.data
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func removeFriend(_ friend: User) async {
        do {
            let response = try await apiService.removeFriend(friendId: friend.id)
            self.friends = response.data
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
