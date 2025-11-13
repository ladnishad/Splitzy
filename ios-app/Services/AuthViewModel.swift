import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    init() {
        checkAuthStatus()
    }

    func checkAuthStatus() {
        if apiService.authToken != nil {
            Task {
                await loadCurrentUser()
            }
        }
    }

    func loadCurrentUser() async {
        do {
            let response = try await apiService.getMe()
            self.currentUser = response.data
            self.isAuthenticated = true
        } catch {
            self.isAuthenticated = false
            self.currentUser = nil
            apiService.clearToken()
        }
    }

    func signup(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiService.signup(email: email, password: password, name: name)
            self.currentUser = User(
                id: response.data.user.id,
                email: response.data.user.email,
                name: response.data.user.name,
                preferences: response.data.user.preferences,
                friends: []
            )
            self.isAuthenticated = true
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiService.login(email: email, password: password)
            self.currentUser = User(
                id: response.data.user.id,
                email: response.data.user.email,
                name: response.data.user.name,
                preferences: response.data.user.preferences,
                friends: []
            )
            self.isAuthenticated = true
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func logout() {
        apiService.clearToken()
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
