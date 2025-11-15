import SwiftUI

struct ItemAssignmentView: View {
    @Binding var bill: Bill
    @Environment(\.dismiss) var dismiss

    @State private var selectedItem: BillItem?
    @State private var selectedParticipant: User?
    @State private var quantityToAssign: Int = 1
    @State private var isAssigning = false
    @State private var errorMessage: String?
    @State private var showFinalize = false

    var body: some View {
        NavigationStack {
            List {
                // Items section
                Section("Items") {
                    ForEach(bill.items) { item in
                        let assignedQuantity = getAssignedQuantity(for: item)
                        let remainingQuantity = item.quantity - assignedQuantity

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.name)
                                    .font(.headline)
                                Spacer()
                                Text("$\(item.cost, specifier: "%.2f")")
                                    .foregroundStyle(.secondary)
                            }

                            HStack {
                                Text("Total qty: \(item.quantity)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if remainingQuantity > 0 {
                                    Text("Remaining: \(remainingQuantity)")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                } else {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                        Text("Fully assigned")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                }
                            }

                            // Show assignments for this item
                            if !getAssignments(for: item).isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(getAssignments(for: item)) { assignment in
                                        HStack {
                                            Image(systemName: "person.fill")
                                                .font(.caption2)
                                                .foregroundStyle(.blue)
                                            Text(assignment.participant.name)
                                                .font(.caption)
                                            Text("× \(assignment.quantity)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Button(role: .destructive) {
                                                Task {
                                                    await removeAssignment(assignment)
                                                }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.red)
                                                    .font(.caption)
                                            }
                                        }
                                        .padding(.leading, 8)
                                    }
                                }
                            }

                            // Assign button
                            if remainingQuantity > 0 {
                                Button {
                                    selectedItem = item
                                } label: {
                                    Label("Assign", systemImage: "person.badge.plus")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }

                // Summary section
                Section("Summary") {
                    ForEach(bill.shares) { share in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(.blue)
                            Text(share.participant.name)
                            Spacer()
                            Text("$\(share.amount, specifier: "%.2f")")
                                .fontWeight(.semibold)
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
            .navigationTitle("Assign Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if allItemsAssigned {
                        Button("Finalize") {
                            showFinalize = true
                        }
                    }
                }
            }
            .sheet(item: $selectedItem) { item in
                AssignItemSheet(
                    bill: $bill,
                    item: item,
                    onAssign: { participant, quantity in
                        Task {
                            await assignItem(item: item, to: participant, quantity: quantity)
                        }
                    }
                )
            }
            .alert("Finalize Bill", isPresented: $showFinalize) {
                Button("Cancel", role: .cancel) { }
                Button("Finalize") {
                    Task {
                        await finalizeBill()
                    }
                }
            } message: {
                Text("Once finalized, assignments cannot be changed. Are you sure?")
            }
        }
    }

    private var allItemsAssigned: Bool {
        for item in bill.items {
            let assignedQty = getAssignedQuantity(for: item)
            if assignedQty < item.quantity {
                return false
            }
        }
        return true
    }

    private func getAssignedQuantity(for item: BillItem) -> Int {
        guard let itemId = item.id else { return 0 }
        return bill.itemAssignments
            .filter { $0.itemId == itemId }
            .reduce(0) { $0 + $1.quantity }
    }

    private func getAssignments(for item: BillItem) -> [ItemAssignment] {
        guard let itemId = item.id else { return [] }
        return bill.itemAssignments.filter { $0.itemId == itemId }
    }

    private func assignItem(item: BillItem, to participant: User, quantity: Int) async {
        guard let itemId = item.id else { return }

        isAssigning = true
        errorMessage = nil

        do {
            let response = try await APIService.shared.assignItem(
                billId: bill.id,
                itemId: itemId,
                participantId: participant.id,
                quantity: quantity
            )
            bill = response.data
            selectedItem = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isAssigning = false
    }

    private func removeAssignment(_ assignment: ItemAssignment) async {
        guard let assignmentId = assignment.id else { return }

        do {
            let response = try await APIService.shared.removeAssignment(
                billId: bill.id,
                assignmentId: assignmentId
            )
            bill = response.data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func finalizeBill() async {
        do {
            let response = try await APIService.shared.finalizeBill(billId: bill.id)
            bill = response.data
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// Sheet for assigning an item to a participant
struct AssignItemSheet: View {
    @Binding var bill: Bill
    let item: BillItem
    let onAssign: (User, Int) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var selectedParticipant: User?
    @State private var quantity: Int = 1

    private var maxQuantity: Int {
        guard let itemId = item.id else { return item.quantity }
        let assigned = bill.itemAssignments
            .filter { $0.itemId == itemId }
            .reduce(0) { $0 + $1.quantity }
        return item.quantity - assigned
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    HStack {
                        Text(item.name)
                            .font(.headline)
                        Spacer()
                        Text("$\(item.cost, specifier: "%.2f")")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Available quantity")
                        Spacer()
                        Text("\(maxQuantity)")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Assign To") {
                    ForEach(bill.participants) { participant in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(.blue)
                            Text(participant.name)
                            Spacer()
                            if selectedParticipant?.id == participant.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedParticipant = participant
                        }
                    }
                }

                if selectedParticipant != nil {
                    Section("Quantity") {
                        Stepper("\(quantity)", value: $quantity, in: 1...maxQuantity)

                        HStack {
                            Text("Total for this assignment")
                            Spacer()
                            Text("$\(item.cost * Double(quantity), specifier: "%.2f")")
                                .fontWeight(.semibold)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Assign Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Assign") {
                        if let participant = selectedParticipant {
                            onAssign(participant, quantity)
                            dismiss()
                        }
                    }
                    .disabled(selectedParticipant == nil)
                }
            }
        }
    }
}

#Preview {
    ItemAssignmentView(bill: .constant(Bill(
        id: "1",
        uploadedBy: User(id: "1", email: "john@example.com", name: "John", preferences: UserPreferences(drinksAlcohol: true, eatsMeat: true, meatTypes: [])),
        imageUrl: "",
        participants: [],
        items: [],
        totalAmount: 0,
        status: .processed,
        assignmentMode: .uploaderAssigns,
        itemAssignments: [],
        shares: [],
        restaurant: Restaurant(name: "Test", type: .restaurant),
        createdAt: ""
    )))
}
