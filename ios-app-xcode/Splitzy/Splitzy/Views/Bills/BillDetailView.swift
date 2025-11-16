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

    var body: some View {
        List {
                // Hero Header Section
                Section {
                    VStack(spacing: 0) {
                        // Bill Image
                        AsyncImage(url: URL(string: "http://localhost:3000\(bill.imageUrl)")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(.gray.opacity(0.1))
                                .frame(height: 200)
                                .overlay {
                                    ProgressView()
                                }
                        }

                        // Restaurant Name & Total
                        VStack(spacing: 12) {
                            // Restaurant Name
                            Text(bill.restaurant.name)
                                .font(.system(.title, design: .rounded))
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            // Restaurant Type Badge
                            HStack(spacing: 6) {
                                Image(systemName: bill.restaurant.type == .restaurant ? "fork.knife" : "cup.and.saucer.fill")
                                    .font(.caption2)
                                Text(bill.restaurant.type.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.secondary.opacity(0.1))
                            .clipShape(Capsule())

                            Divider()
                                .padding(.vertical, 8)

                            // Total Amount - Hero style
                            VStack(spacing: 4) {
                                Text("Total Amount")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                    .tracking(1)

                                Text("$\(bill.totalAmount, specifier: "%.2f")")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(.blue)
                            }
                            .padding(.bottom, 8)

                            // Status Badge
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(statusColor)
                                    .frame(width: 8, height: 8)
                                Text(bill.status.displayName)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(statusColor.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                    }
                    .listRowInsets(EdgeInsets())
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
                Section {
                    ForEach(bill.shares) { share in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(share.amount > 0 ? AnyShapeStyle(Color.blue.gradient) : AnyShapeStyle(Color.gray.opacity(0.2)))
                                    .frame(width: 44, height: 44)

                                Text(String(share.participant.name.prefix(1)))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(share.participant.name)
                                    .font(.body)
                                    .fontWeight(.medium)

                                if share.participant.id == currentUserId {
                                    Text("You")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                } else {
                                    Text(share.participant.email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Text("$\(share.amount, specifier: "%.2f")")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(share.amount > 0 ? .primary : .secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    if bill.status == .finalized {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Text("Bill finalized and ready for payment")
                                .foregroundStyle(.green)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Who Owes What")
                }
            }

            // Participants
            Section {
                ForEach(bill.participants) { participant in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(participant.id == currentUserId ? AnyShapeStyle(Color.blue.gradient) : AnyShapeStyle(Color.gray.opacity(0.3)))
                                .frame(width: 44, height: 44)

                            Text(String(participant.name.prefix(1)))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(participant.name)
                                    .font(.body)
                                    .fontWeight(.medium)

                                // Star icon for uploader
                                if participant.id == bill.uploadedBy.id {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.yellow)
                                }

                                // Checkmark icon if participant has finished claiming
                                if bill.assignmentMode == .selfSelect,
                                   bill.participantsFinished.contains(where: { $0.id == participant.id }) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.green)
                                }
                            }

                            HStack(spacing: 4) {
                                if participant.id == currentUserId {
                                    Text("You")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                    Text("•")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(participant.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        // Show "Claim Items" button for current user in self_select mode
                        if let userId = currentUserId,
                           participant.id == userId,
                           bill.assignmentMode == .selfSelect,
                           bill.status != .finalized {
                            Button {
                                Task {
                                    await refreshBill()
                                    showClaimView = true
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text("Claim")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.blue.gradient)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Participants")
            }


            // Items (if processed)
            if !bill.items.isEmpty {
                Section {
                    ForEach(bill.items) { item in
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.blue.opacity(0.1))
                                    .frame(width: 40, height: 40)

                                Image(systemName: "fork.knife")
                                    .font(.body)
                                    .foregroundStyle(.blue)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name)
                                    .font(.body)
                                    .fontWeight(.medium)

                                HStack(spacing: 4) {
                                    Text("\(item.quantity)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.blue)
                                    Text("×")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("$\(item.cost, specifier: "%.2f")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Text("$\(item.cost * Double(item.quantity), specifier: "%.2f")")
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 4)
                    }

                    // Total row with emphasis
                    HStack {
                        Text("Total")
                            .font(.headline)
                            .fontWeight(.bold)
                        Spacer()
                        Text("$\(bill.totalAmount, specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.blue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                } header: {
                    Text("Items")
                }
            } else {
                Section {
                    ContentUnavailableView(
                        "No Items Yet",
                        systemImage: "fork.knife.circle",
                        description: Text("Items will appear here once the bill is processed")
                    )
                }
            }
        }
        .navigationTitle(bill.restaurant.name)
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

    private var statusColor: Color {
        switch bill.status {
        case .uploaded:
            return .orange
        case .processing:
            return .blue
        case .processed:
            return .purple
        case .split:
            return .teal
        case .finalized:
            return .green
        }
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
