import SwiftUI

struct ItemClaimView: View {
    @Binding var bill: Bill
    let currentUserId: String
    @Environment(\.dismiss) var dismiss

    @State private var selectedItem: BillItem?
    @State private var quantityToClaim: Int = 1
    @State private var isClaiming = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                // Items section
                Section("Available Items") {
                    ForEach(bill.items) { item in
                        let assignedQuantity = getAssignedQuantity(for: item)
                        let remainingQuantity = item.quantity - assignedQuantity
                        let myClaims = getMyClaims(for: item)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.name)
                                    .font(.headline)
                                Spacer()
                                Text("$\(item.cost, specifier: "%.2f") each")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                            }

                            HStack {
                                Text("Available: \(remainingQuantity)")
                                    .font(.caption)
                                    .foregroundStyle(remainingQuantity > 0 ? .green : .secondary)
                                Spacer()
                                if !myClaims.isEmpty {
                                    let myTotal = myClaims.reduce(0) { $0 + $1.quantity }
                                    Text("You claimed: \(myTotal)")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                            }

                            // Show my claims for this item
                            if !myClaims.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(myClaims) { claim in
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.caption2)
                                                .foregroundStyle(.blue)
                                            Text("× \(claim.quantity)")
                                                .font(.caption)
                                            Text("($\(item.cost * Double(claim.quantity), specifier: "%.2f"))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Button(role: .destructive) {
                                                Task {
                                                    await removeClaim(claim)
                                                }
                                            } label: {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundStyle(.red)
                                                    .font(.caption)
                                            }
                                        }
                                        .padding(.leading, 8)
                                    }
                                }
                            }

                            // Claim button
                            if remainingQuantity > 0 {
                                Button {
                                    selectedItem = item
                                    quantityToClaim = min(1, remainingQuantity)
                                } label: {
                                    Label("Claim", systemImage: "plus.circle")
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // My total section
                Section("Your Total") {
                    if let myShare = bill.shares.first(where: { $0.participant.id == currentUserId }) {
                        HStack {
                            Text("You owe")
                                .font(.headline)
                            Spacer()
                            Text("$\(myShare.amount, specifier: "%.2f")")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                        }
                    } else {
                        Text("You haven't claimed any items yet")
                            .foregroundStyle(.secondary)
                    }
                }

                // All participants summary
                Section("Everyone's Share") {
                    ForEach(bill.shares) { share in
                        HStack {
                            Image(systemName: share.participant.id == currentUserId ? "person.fill" : "person")
                                .foregroundStyle(.blue)
                            Text(share.participant.name)
                                .fontWeight(share.participant.id == currentUserId ? .semibold : .regular)
                            Spacer()
                            Text("$\(share.amount, specifier: "%.2f")")
                                .foregroundStyle(share.amount > 0 ? .blue : .secondary)
                        }
                    }
                }

                // Error message
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Claim Your Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedItem) { item in
                ClaimItemSheet(
                    item: item,
                    maxQuantity: getMaxQuantityToClaim(for: item),
                    onClaim: { quantity in
                        Task {
                            await claimItem(item: item, quantity: quantity)
                        }
                    }
                )
            }
        }
    }

    private func getAssignedQuantity(for item: BillItem) -> Int {
        guard let itemId = item.id else { return 0 }
        return bill.itemAssignments
            .filter { $0.itemId == itemId }
            .reduce(0) { $0 + $1.quantity }
    }

    private func getMaxQuantityToClaim(for item: BillItem) -> Int {
        guard let itemId = item.id else { return 0 }
        let assigned = bill.itemAssignments
            .filter { $0.itemId == itemId }
            .reduce(0) { $0 + $1.quantity }
        return item.quantity - assigned
    }

    private func getMyClaims(for item: BillItem) -> [ItemAssignment] {
        guard let itemId = item.id else { return [] }
        return bill.itemAssignments.filter {
            $0.itemId == itemId && $0.participant.id == currentUserId
        }
    }

    private func claimItem(item: BillItem, quantity: Int) async {
        guard let itemId = item.id else { return }

        isClaiming = true
        errorMessage = nil

        do {
            let response = try await APIService.shared.claimItem(
                billId: bill.id,
                itemId: itemId,
                quantity: quantity
            )
            bill = response.data
            selectedItem = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isClaiming = false
    }

    private func removeClaim(_ claim: ItemAssignment) async {
        guard let claimId = claim.id else { return }

        do {
            let response = try await APIService.shared.removeAssignment(
                billId: bill.id,
                assignmentId: claimId
            )
            bill = response.data
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// Sheet for claiming an item
struct ClaimItemSheet: View {
    let item: BillItem
    let maxQuantity: Int
    let onClaim: (Int) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var quantity: Int = 1

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    HStack {
                        Text(item.name)
                            .font(.headline)
                        Spacer()
                        Text("$\(item.cost, specifier: "%.2f") each")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Available quantity")
                        Spacer()
                        Text("\(maxQuantity)")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("How Many?") {
                    Stepper("\(quantity)", value: $quantity, in: 1...max(1, maxQuantity))

                    HStack {
                        Text("Your total for this item")
                        Spacer()
                        Text("$\(item.cost * Double(quantity), specifier: "%.2f")")
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .navigationTitle("Claim Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Claim") {
                        onClaim(quantity)
                        dismiss()
                    }
                    .disabled(maxQuantity < 1)
                }
            }
        }
    }
}

#Preview {
    ItemClaimView(
        bill: .constant(Bill(
            id: "1",
            uploadedBy: User(id: "1", email: "john@example.com", name: "John", preferences: UserPreferences(drinksAlcohol: true, eatsMeat: true, meatTypes: [])),
            imageUrl: "",
            participants: [],
            items: [],
            totalAmount: 0,
            status: .processed,
            assignmentMode: .selfSelect,
            itemAssignments: [],
            shares: [],
            restaurant: Restaurant(name: "Test", type: .restaurant),
            createdAt: ""
        )),
        currentUserId: "1"
    )
}
