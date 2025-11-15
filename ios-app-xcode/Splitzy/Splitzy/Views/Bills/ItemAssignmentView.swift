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

    var allItemsAssigned: Bool {
        for item in bill.items {
            let assignedQty = getAssignedQuantity(for: item)
            if assignedQty < item.quantity {
                return false
            }
        }
        return true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if bill.items.isEmpty {
                    ContentUnavailableView(
                        "No Items",
                        systemImage: "cart",
                        description: Text("This bill doesn't have any items yet")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Progress Card
                            if !bill.items.isEmpty {
                                VStack(spacing: 12) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Assignment Progress")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)

                                            if allItemsAssigned {
                                                HStack(spacing: 8) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundStyle(.green)
                                                    Text("All items assigned!")
                                                        .font(.title3)
                                                        .fontWeight(.semibold)
                                                        .foregroundStyle(.green)
                                                }
                                            } else {
                                                let totalItems = bill.items.reduce(0) { $0 + $1.quantity }
                                                let assignedItems = bill.items.reduce(0) { sum, item in
                                                    sum + getAssignedQuantity(for: item)
                                                }
                                                Text("\(assignedItems) / \(totalItems) items")
                                                    .font(.title3)
                                                    .fontWeight(.semibold)
                                            }
                                        }
                                        Spacer()

                                        if allItemsAssigned {
                                            Button {
                                                showFinalize = true
                                            } label: {
                                                HStack {
                                                    Image(systemName: "checkmark.seal.fill")
                                                    Text("Finalize")
                                                }
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 12)
                                                .background(.green.gradient)
                                                .clipShape(Capsule())
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(allItemsAssigned ? .green.opacity(0.1) : .orange.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .padding(.horizontal)
                            }

                            // Items
                            VStack(spacing: 16) {
                                ForEach(bill.items) { item in
                                    ItemAssignmentCard(
                                        item: item,
                                        bill: bill,
                                        onAssign: {
                                            selectedItem = item
                                        },
                                        onRemoveAssignment: { assignment in
                                            Task { await removeAssignment(assignment) }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)

                            // Shares Summary
                            if !bill.shares.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Share Breakdown")
                                        .font(.headline)
                                        .padding(.horizontal)

                                    VStack(spacing: 0) {
                                        ForEach(bill.shares) { share in
                                            HStack {
                                                HStack(spacing: 12) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(.blue.gradient)
                                                            .frame(width: 40, height: 40)

                                                        Text(String(share.participant.name.prefix(1)))
                                                            .font(.headline)
                                                            .foregroundStyle(.white)
                                                    }

                                                    Text(share.participant.name)
                                                        .font(.body)
                                                }

                                                Spacer()

                                                Text("$\(share.amount, specifier: "%.2f")")
                                                    .font(.headline)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(share.amount > 0 ? .blue : .secondary)
                                            }
                                            .padding()

                                            if share.id != bill.shares.last?.id {
                                                Divider()
                                                    .padding(.leading, 68)
                                            }
                                        }
                                    }
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                }
                                .padding(.horizontal)
                            }

                            // Error message
                            if let errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.red)
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                                .padding()
                                .background(.red.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .background(Color(.systemGroupedBackground))
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

// Individual Item Assignment Card
struct ItemAssignmentCard: View {
    let item: BillItem
    let bill: Bill
    let onAssign: () -> Void
    let onRemoveAssignment: (ItemAssignment) -> Void

    private var assignedQuantity: Int {
        guard let itemId = item.id else { return 0 }
        return bill.itemAssignments
            .filter { $0.itemId == itemId }
            .reduce(0) { $0 + $1.quantity }
    }

    private var remainingQuantity: Int {
        item.quantity - assignedQuantity
    }

    private var assignments: [ItemAssignment] {
        guard let itemId = item.id else { return [] }
        return bill.itemAssignments.filter { $0.itemId == itemId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Item Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.title3)
                        .fontWeight(.semibold)

                    HStack(spacing: 16) {
                        Label("\(item.quantity) total", systemImage: "number")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Label("$\(item.cost, specifier: "%.2f") each", systemImage: "dollarsign.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if remainingQuantity > 0 {
                        Text("\(remainingQuantity) left")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.15))
                            .clipShape(Capsule())
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                            Text("Complete")
                        }
                        .font(.caption)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
            }

            // Assignments
            if !assignments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(.blue)
                        Text("Assigned to:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                    }

                    ForEach(assignments) { assignment in
                        HStack {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(.blue.opacity(0.2))
                                        .frame(width: 28, height: 28)

                                    Text(String(assignment.participant.name.prefix(1)))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.blue)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(assignment.participant.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    HStack(spacing: 4) {
                                        Text("\(assignment.quantity)×")
                                        Text("$\(item.cost, specifier: "%.2f")")
                                        Text("=")
                                        Text("$\(item.cost * Double(assignment.quantity), specifier: "%.2f")")
                                            .fontWeight(.semibold)
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Button(role: .destructive) {
                                onRemoveAssignment(assignment)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                    .font(.title3)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.blue.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            // Assign Button
            if remainingQuantity > 0 {
                Button {
                    onAssign()
                } label: {
                    HStack {
                        Image(systemName: "person.badge.plus.fill")
                        Text("Assign to Someone")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                    .padding()
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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
            VStack(spacing: 0) {
                itemInfoCard
                participantsList
                quantitySection
                assignButton
            }
            .navigationTitle("Assign Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var itemInfoCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Label("$\(item.cost, specifier: "%.2f") each", systemImage: "dollarsign.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Divider()

            HStack {
                Text("Available")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(maxQuantity)")
                    .fontWeight(.semibold)
                    .font(.title3)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(.gray.opacity(0.05))
    }

    private var participantsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("Assign to")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                ForEach(bill.participants) { participant in
                    participantRow(participant)

                    if participant.id != bill.participants.last?.id {
                        Divider()
                            .padding(.leading, 68)
                    }
                }
            }
        }
    }

    private func participantRow(_ participant: User) -> some View {
        Button {
            selectedParticipant = participant
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(selectedParticipant?.id == participant.id ? Color.blue : Color.gray.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Text(String(participant.name.prefix(1)))
                        .font(.headline)
                        .foregroundStyle(selectedParticipant?.id == participant.id ? .white : .gray)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(participant.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text(participant.email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if selectedParticipant?.id == participant.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                }
            }
            .padding()
            .background(selectedParticipant?.id == participant.id ? .blue.opacity(0.05) : .clear)
        }
    }

    @ViewBuilder
    private var quantitySection: some View {
        if selectedParticipant != nil {
            VStack(spacing: 16) {
                Divider()

                HStack(spacing: 20) {
                    Button {
                        if quantity > 1 {
                            quantity -= 1
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(quantity > 1 ? .blue : .gray)
                    }
                    .disabled(quantity <= 1)

                    VStack(spacing: 4) {
                        Text("Quantity")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(quantity)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.blue)
                    }
                    .frame(minWidth: 80)

                    Button {
                        if quantity < maxQuantity {
                            quantity += 1
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(quantity < maxQuantity ? .blue : .gray)
                    }
                    .disabled(quantity >= maxQuantity)
                }
                .padding(.vertical)

                HStack {
                    Text("Total")
                    Spacer()
                    Text("$\(item.cost * Double(quantity), specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
                .padding()
                .background(.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }

    @ViewBuilder
    private var assignButton: some View {
        if selectedParticipant != nil {
            Button {
                if let participant = selectedParticipant {
                    onAssign(participant, quantity)
                    dismiss()
                }
            } label: {
                HStack {
                    Image(systemName: "person.badge.plus.fill")
                    Text("Assign \(quantity) to \(selectedParticipant?.name ?? "")")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
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
