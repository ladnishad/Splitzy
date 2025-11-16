import SwiftUI

struct BillDetailView: View {
    @State var bill: Bill
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var showAssignmentView = false
    @State private var showClaimView = false
    @State private var currentUserId: String?
    @State private var userLoadError: String?
    @Environment(\.dismiss) var dismiss

    private var showFloatingClaimButton: Bool {
        guard let userId = currentUserId else { return false }
        let isParticipant = bill.participants.contains { $0.id == userId }
        return bill.assignmentMode == .selfSelect &&
               bill.status != .finalized &&
               isParticipant
    }

    var body: some View {
        ZStack(alignment: .bottom) {
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

                // DEBUG: Show raw assignment mode value
                Section("Debug Info") {
                    LabeledContent("Assignment Mode", value: bill.assignmentMode.rawValue)
                    LabeledContent("Current User ID", value: currentUserId ?? "nil")
                    if let error = userLoadError {
                        LabeledContent("User Load Error", value: error)
                    }
                    LabeledContent("Is Uploader", value: String(isUploader))
                    LabeledContent("Uploader ID", value: bill.uploadedBy.id)
                    LabeledContent("Participants Count", value: String(bill.participants.count))
                    if let userId = currentUserId {
                        let isParticipant = bill.participants.contains { $0.id == userId }
                        LabeledContent("Is Participant", value: String(isParticipant))
                    }
                    LabeledContent("Show Button", value: String(showFloatingClaimButton))
                }

                // Assignment Mode
                if bill.assignmentMode != .notSet {
                    Section {
                        HStack {
                            Text("Split Mode")
                            Spacer()
                            Text(bill.assignmentMode.displayName)
                                .foregroundStyle(.secondary)
                        }

                        // Show assign button for uploader in uploader_assigns mode
                        if bill.status != .finalized && bill.assignmentMode == .uploaderAssigns && isUploader {
                            Button {
                                Task {
                                    await refreshBill()
                                    showAssignmentView = true
                                }
                            } label: {
                                Label("Assign Items", systemImage: "person.badge.plus")
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
            // Add padding at bottom when floating button is visible
            if showFloatingClaimButton {
                Section {
                    Color.clear
                        .frame(height: 80)
                        .listRowBackground(Color.clear)
                }
            }
        }

        // Floating Claim Button
        if showFloatingClaimButton {
            VStack(spacing: 0) {
                // Shadow/gradient separator
                LinearGradient(
                    colors: [.clear, .black.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 8)

                Button {
                    Task {
                        await refreshBill()
                        showClaimView = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .font(.title3)
                        Text("Claim Your Items")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(.blue.gradient)
                }
                .buttonStyle(.plain)
            }
            .background(.ultraThinMaterial)
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
            await refreshBill()
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
            userLoadError = nil
        } catch {
            userLoadError = error.localizedDescription

            // Workaround: Try to extract user ID from bill data
            // Check if we're the uploader or in participants list
            // This works because the bill was already loaded successfully with auth
            if let token = UserDefaults.standard.string(forKey: "authToken") {
                // Decode the JWT token to get user ID
                if let userId = decodeJWTUserId(token: token) {
                    currentUserId = userId
                    userLoadError = "Using ID from token (getMe failed: \(error.localizedDescription))"
                }
            }
        }
    }

    private func decodeJWTUserId(token: String) -> String? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }

        var payload = String(parts[1])
        // Add padding if needed
        let remainder = payload.count % 4
        if remainder > 0 {
            payload += String(repeating: "=", count: 4 - remainder)
        }

        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let userId = json["id"] as? String else {
            return nil
        }

        return userId
    }

    private func refreshBill() async {
        do {
            let response = try await APIService.shared.getBill(id: bill.id)
            bill = response.data
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
