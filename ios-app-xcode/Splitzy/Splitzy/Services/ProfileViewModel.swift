import Foundation
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var drinksAlcohol = false
    @Published var eatsMeat = true
    @Published var selectedMeatTypes: Set<String> = []

    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private var originalPreferences: UserPreferences?
    private let apiService = APIService.shared

    var hasChanges: Bool {
        guard let original = originalPreferences else { return false }

        return drinksAlcohol != original.drinksAlcohol ||
               eatsMeat != original.eatsMeat ||
               selectedMeatTypes != Set(original.meatTypes)
    }

    func loadPreferences(from user: User?) {
        guard let preferences = user?.preferences else { return }

        self.originalPreferences = preferences
        self.drinksAlcohol = preferences.drinksAlcohol
        self.eatsMeat = preferences.eatsMeat
        self.selectedMeatTypes = Set(preferences.meatTypes)
    }

    func savePreferences() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil

        let preferences = UserPreferences(
            drinksAlcohol: drinksAlcohol,
            eatsMeat: eatsMeat,
            meatTypes: Array(selectedMeatTypes)
        )

        do {
            let response = try await apiService.updatePreferences(preferences: preferences)
            self.originalPreferences = response.data.preferences
            self.successMessage = "Preferences saved successfully"

            // Clear success message after 3 seconds
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            self.successMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}
