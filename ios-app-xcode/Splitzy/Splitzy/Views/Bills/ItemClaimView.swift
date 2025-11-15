import SwiftUI

struct ItemClaimView: View {
    @Binding var bill: Bill
    let currentUserId: String
    @Environment(\.dismiss) var dismiss

    @State private var selectedItem: BillItem?
    @State private var quantityToClaim: Int = 1
    @State private var isClaiming = false
    @State private var errorMessage: String?

    var myTotal: Double {
        guard let myShare = bill.shares.first(where: { $0.participant.id == currentUserId }) else {
            return 0
        }
        return myShare.amount
    }

    var body: some View {
        NavigationStack {
            contentView
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

    @ViewBuilder
    private var contentView: some View {
        if bill.items.isEmpty {
            emptyStateView
        } else {
            mainScrollView
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Items",
            systemImage: "cart",
            description: Text("This bill doesn't have any items yet")
        )
    }

    private var mainScrollView: some View {
        ScrollView {
            VStack(spacing: 20) {
                totalCard
                itemsList
                sharesSection
                errorSection
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var totalCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Total")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("$\(myTotal, specifier: "%.2f")")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
                Spacer()
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue.gradient)
            }
            .padding()
            .background(.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal)
    }

    private var itemsList: some View {
        VStack(spacing: 16) {
            ForEach(bill.items) { item in
                ItemClaimCard(
                    item: item,
                    bill: bill,
                    currentUserId: currentUserId,
                    onClaim: {
                        selectedItem = item
                        quantityToClaim = min(1, getMaxQuantityToClaim(for: item))
                    },
                    onRemoveClaim: { claim in
                        Task { await removeClaim(claim) }
                    }
                )
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var sharesSection: some View {
        if !bill.shares.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Everyone's Share")
                    .font(.headline)
                    .padding(.horizontal)

                sharesList
            }
            .padding(.horizontal)
        }
    }

    private var sharesList: some View {
        VStack(spacing: 0) {
            ForEach(bill.shares) { share in
                shareRow(for: share)

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

    private func shareRow(for share: BillShare) -> some View {
        HStack {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(share.participant.id == currentUserId ? .blue.gradient : Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)

                    Text(String(share.participant.name.prefix(1)))
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(share.participant.name)
                        .font(.body)
                        .fontWeight(share.participant.id == currentUserId ? .semibold : .regular)
                    if share.participant.id == currentUserId {
                        Text("You")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }

            Spacer()

            Text("$\(share.amount, specifier: "%.2f")")
                .font(.headline)
                .foregroundStyle(share.amount > 0 ? .primary : .secondary)
        }
        .padding()
        .background(share.participant.id == currentUserId ? Color.blue.opacity(0.05) : Color.clear)
    }

    @ViewBuilder
    private var errorSection: some View {
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

// Individual Item Card
struct ItemClaimCard: View {
    let item: BillItem
    let bill: Bill
    let currentUserId: String
    let onClaim: () -> Void
    let onRemoveClaim: (ItemAssignment) -> Void

    private var assignedQuantity: Int {
        guard let itemId = item.id else { return 0 }
        return bill.itemAssignments
            .filter { $0.itemId == itemId }
            .reduce(0) { $0 + $1.quantity }
    }

    private var remainingQuantity: Int {
        item.quantity - assignedQuantity
    }

    private var myClaims: [ItemAssignment] {
        guard let itemId = item.id else { return [] }
        return bill.itemAssignments.filter {
            $0.itemId == itemId && $0.participant.id == currentUserId
        }
    }

    private var myClaimedTotal: Int {
        myClaims.reduce(0) { $0 + $1.quantity }
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
                            .foregroundStyle(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.green.opacity(0.15))
                            .clipShape(Capsule())
                    } else {
                        Text("All claimed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.gray.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }

            // My Claims
            if !myClaims.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.blue)
                        Text("You claimed \(myClaimedTotal)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                    }

                    ForEach(myClaims) { claim in
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "multiply")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("\(claim.quantity)")
                                    .fontWeight(.medium)
                                Text("× $\(item.cost, specifier: "%.2f")")
                                    .foregroundStyle(.secondary)
                                Text("= $\(item.cost * Double(claim.quantity), specifier: "%.2f")")
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)

                            Spacer()

                            Button(role: .destructive) {
                                onRemoveClaim(claim)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                                    .font(.title3)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.blue.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            // Claim Button
            if remainingQuantity > 0 {
                Button {
                    onClaim()
                } label: {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                        Text("Claim This")
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

// Sheet for claiming an item
struct ClaimItemSheet: View {
    let item: BillItem
    let maxQuantity: Int
    let onClaim: (Int) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var quantity: Int = 1

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Item Info Card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            HStack(spacing: 12) {
                                Label("$\(item.cost, specifier: "%.2f") each", systemImage: "dollarsign.circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
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

                // Quantity Picker
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("How many?")
                            .font(.headline)

                        HStack(spacing: 20) {
                            Button {
                                if quantity > 1 {
                                    quantity -= 1
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(quantity > 1 ? .blue : .gray)
                            }
                            .disabled(quantity <= 1)

                            Text("\(quantity)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.blue)
                                .frame(minWidth: 80)

                            Button {
                                if quantity < maxQuantity {
                                    quantity += 1
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(quantity < maxQuantity ? .blue : .gray)
                            }
                            .disabled(quantity >= maxQuantity)
                        }
                    }
                    .padding()

                    // Total Display
                    VStack(spacing: 8) {
                        Text("Your total for this")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("$\(item.cost * Double(quantity), specifier: "%.2f")")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.blue)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
                .padding(.vertical, 32)

                Spacer()

                // Claim Button
                Button {
                    onClaim(quantity)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                        Text("Claim \(quantity) Item\(quantity > 1 ? "s" : "")")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(maxQuantity < 1)
                .padding()
            }
            .navigationTitle("Claim Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
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
