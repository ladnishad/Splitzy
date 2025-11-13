import Foundation
import SwiftUI

@MainActor
class BillsViewModel: ObservableObject {
    @Published var bills: [Bill] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func loadBills() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiService.getBills()
            self.bills = response.data
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func deleteBill(_ bill: Bill) async {
        do {
            _ = try await apiService.deleteBill(id: bill.id)
            bills.removeAll { $0.id == bill.id }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
