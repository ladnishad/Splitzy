import SwiftUI

struct BillDetailView: View {
    @State var bill: Bill
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var showAssignmentView = false
    @State private var showClaimView = false
    @State private var showSplitModeInfo = false
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

                            // Split Mode Badge with Info
                            if bill.assignmentMode != .notSet {
                                Button {
                                    showSplitModeInfo = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: splitModeIcon)
                                            .font(.caption2)
                                        Text(splitModeDisplayName)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        Image(systemName: "info.circle")
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(splitModeColor)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(splitModeColor.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                    }
                    .listRowInsets(EdgeInsets())
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

            // Participants with amounts or claim button
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

                            if participant.id == currentUserId {
                                Text("You")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }

                        Spacer()

                        // Show amount or claim button - both tappable for current user
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
                                if bill.participantsFinished.contains(where: { $0.id == participant.id }) {
                                    // Show amount with tap hint
                                    HStack(spacing: 6) {
                                        Text("$\(bill.shares.first(where: { $0.participant.id == participant.id })?.amount ?? 0, specifier: "%.2f")")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                    }
                                    .foregroundStyle(.blue)
                                } else {
                                    // Show claim button
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
                            }
                            .buttonStyle(.plain)
                        } else if !bill.shares.isEmpty {
                            // For other participants, always show their amount (not tappable)
                            if let share = bill.shares.first(where: { $0.participant.id == participant.id }) {
                                Text("$\(share.amount, specifier: "%.2f")")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(share.amount > 0 ? .primary : .secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Add participant button (only for uploader)
                if isUploader && bill.status != .finalized {
                    Button {
                        // TODO: Add participant functionality
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.plus")
                                .font(.body)
                            Text("Add Participant")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }

                // Show assign items button for uploader in uploader_assigns mode
                if bill.assignmentMode == .uploaderAssigns && isUploader && bill.status != .finalized {
                    Button {
                        Task {
                            await refreshBill()
                            showAssignmentView = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.pencil")
                                .font(.body)
                            Text("Assign Items")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
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
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            } header: {
                Text("Participants")
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
        .alert("Split Modes", isPresented: $showSplitModeInfo) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text(splitModeInfoMessage)
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

    private var splitModeDisplayName: String {
        switch bill.assignmentMode {
        case .selfSelect:
            return "Let'em Pick"
        case .uploaderAssigns:
            return "I'll Assign"
        case .notSet:
            return "Not Set"
        }
    }

    private var splitModeIcon: String {
        switch bill.assignmentMode {
        case .selfSelect:
            return "hand.tap.fill"
        case .uploaderAssigns:
            return "person.crop.circle.badge.checkmark"
        case .notSet:
            return "questionmark.circle"
        }
    }

    private var splitModeColor: Color {
        switch bill.assignmentMode {
        case .selfSelect:
            return .purple
        case .uploaderAssigns:
            return .blue
        case .notSet:
            return .gray
        }
    }

    private var splitModeInfoMessage: String {
        """
        Let'em Pick: Everyone selects their own items from the bill. Perfect for groups where people know what they ordered.

        I'll Assign: As the bill uploader, you assign items to participants. Best when you want to control the split.
        """
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
