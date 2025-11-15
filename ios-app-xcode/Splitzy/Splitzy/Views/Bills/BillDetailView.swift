import SwiftUI

struct BillDetailView: View {
    @State var bill: Bill
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var showAssignmentView = false
    @State private var showClaimView = false
    @State private var currentUserId: String?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            // Bill Image Section
            Section {
                AsyncImage(url: URL(string: "http://localhost:3000\(bill.imageUrl)")) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
            }

            // Restaurant Info
            Section("Restaurant Details") {
                LabeledContent("Name", value: bill.restaurant.name)
                LabeledContent("Type", value: bill.restaurant.type.displayName)
                LabeledContent("Status", value: bill.status.displayName)
            }

            // Assignment Mode & Actions
            if bill.assignmentMode != .notSet {
                Section {
                    HStack {
                        Text("Split Mode")
                        Spacer()
                        Text(bill.assignmentMode.displayName)
                            .foregroundStyle(.secondary)
                    }

                    // Show appropriate action button
                    if isUploader {
                        if bill.assignmentMode == .uploaderAssigns && bill.status != .finalized {
                            Button {
                                showAssignmentView = true
                            } label: {
                                Label("Assign Items", systemImage: "person.badge.plus")
                            }
                        }
                    } else {
                        if bill.assignmentMode == .selfSelect && bill.status != .finalized {
                            Button {
                                showClaimView = true
                            } label: {
                                Label("Claim Items", systemImage: "hand.raised")
                            }
                        }
                    }
                } header: {
                    Text("Bill Splitting")
                }
            }

            // Shares - Who owes what
            if !bill.shares.isEmpty {
                Section("Who Owes What") {
                    ForEach(bill.shares) { share in
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundStyle(.green)

                            Text(share.participant.name)
                                .font(.body)

                            Spacer()

                            Text("$\(share.amount, specifier: "%.2f")")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(share.amount > 0 ? .blue : .secondary)
                        }
                    }

                    if bill.status == .finalized {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Text("Bill finalized")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                }
            }

            // Participants
            Section("Participants") {
                ForEach(bill.participants) { participant in
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading) {
                            Text(participant.name)
                                .font(.body)
                            Text(participant.email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if participant.id == bill.uploadedBy.id {
                            Spacer()
                            Text("Uploader")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.2))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Items (if processed)
            if !bill.items.isEmpty {
                Section("Items") {
                    ForEach(bill.items) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.body)
                                Text("Qty: \(item.quantity)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("$\(item.cost * Double(item.quantity), specifier: "%.2f")")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }

                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text("$\(bill.totalAmount, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }
                }
            } else {
                Section {
                    ContentUnavailableView(
                        "No Items Yet",
                        systemImage: "list.bullet",
                        description: Text("Items will appear here once the bill is processed")
                    )
                }
            }
        }
        .navigationTitle("Bill Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Bill", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Bill", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteBill()
                }
            }
        } message: {
            Text("Are you sure you want to delete this bill? This action cannot be undone.")
        }
        .sheet(isPresented: $showAssignmentView) {
            ItemAssignmentView(bill: $bill)
        }
        .sheet(isPresented: $showClaimView) {
            if let userId = currentUserId {
                ItemClaimView(bill: $bill, currentUserId: userId)
            }
        }
        .task {
            await loadCurrentUser()
        }
        .disabled(isDeleting)
    }

    private var isUploader: Bool {
        guard let userId = currentUserId else { return false }
        return bill.uploadedBy.id == userId
    }

    private func loadCurrentUser() async {
        do {
            let response = try await APIService.shared.getMe()
            currentUserId = response.data.id
        } catch {
            // Handle error silently
        }
    }

    private func deleteBill() async {
        isDeleting = true

        do {
            _ = try await APIService.shared.deleteBill(id: bill.id)
            dismiss()
        } catch {
            // Handle error silently for now
            isDeleting = false
        }
    }
}
