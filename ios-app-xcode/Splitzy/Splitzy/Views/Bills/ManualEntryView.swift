import SwiftUI

struct ManualEntryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var friendsViewModel = FriendsViewModel()

    @State private var restaurantName = ""
    @State private var selectedParticipants: Set<String> = []
    @State private var items: [ManualBillItem] = []
    @State private var assignmentMode: AssignmentMode = .uploaderAssigns
    @State private var isCreating = false
    @State private var errorMessage: String?

    var totalAmount: Double {
        items.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }

    var canCreate: Bool {
        !restaurantName.isEmpty && !selectedParticipants.isEmpty && !items.isEmpty
    }

    var body: some View {
        Form {
            // Restaurant Details
            Section("Restaurant Details") {
                TextField("Restaurant Name", text: $restaurantName)
            }

            // Items (moved before participants)
            Section {
                ForEach(items.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 12) {
                        // Item name
                        HStack {
                            TextField("Item name", text: $items[index].name)
                                .font(.body)

                            Button(role: .destructive) {
                                items.remove(at: index)
                            } label: {
                                Image(systemName: "trash.circle.fill")
                                    .foregroundStyle(.red)
                                    .font(.title3)
                            }
                        }

                        // Price per item
                        HStack {
                            Text("Price per item")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Spacer()

                            TextField("0.00", value: $items[index].price, format: .currency(code: "USD"))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .font(.body)
                                .frame(width: 100)
                        }

                        // Quantity selector with total
                        VStack(spacing: 6) {
                            HStack {
                                Text("Quantity")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Stepper("\(items[index].quantity)", value: $items[index].quantity, in: 1...99)
                                    .fixedSize()
                            }

                            // Total for this item
                            HStack {
                                Text("Item total")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text("$\(items[index].price * Double(items[index].quantity), specifier: "%.2f")")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                            }
                        }

                        Divider()
                    }
                    .padding(.vertical, 4)
                }

                Button {
                    items.append(ManualBillItem())
                } label: {
                    Label("Add Item", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Items")
            } footer: {
                if !items.isEmpty {
                    HStack {
                        Text("Bill Total")
                            .fontWeight(.semibold)
                            .font(.headline)
                        Spacer()
                        Text("$\(totalAmount, specifier: "%.2f")")
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                            .font(.headline)
                    }
                    .padding(.top, 4)
                }
            }

            // Participants (moved after items)
            Section {
                if friendsViewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if friendsViewModel.friends.isEmpty {
                    Text("No friends added yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(friendsViewModel.friends, id: \.id) { friend in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(.blue)

                            Text(friend.name)

                            Spacer()

                            if selectedParticipants.contains(friend.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedParticipants.contains(friend.id) {
                                selectedParticipants.remove(friend.id)
                            } else {
                                selectedParticipants.insert(friend.id)
                            }
                        }
                    }
                }
            } header: {
                Text("Participants")
            } footer: {
                Text("You will be automatically added")
            }

            // Assignment Mode
            Section {
                Picker("Assignment Mode", selection: $assignmentMode) {
                    Text(AssignmentMode.uploaderAssigns.displayName).tag(AssignmentMode.uploaderAssigns)
                    Text(AssignmentMode.selfSelect.displayName).tag(AssignmentMode.selfSelect)
                }
                .pickerStyle(.segmented)
            } header: {
                Text("How to Split")
            } footer: {
                if assignmentMode == .uploaderAssigns {
                    Text("You'll assign items to each participant")
                } else {
                    Text("Participants will claim their own items")
                }
            }

            // Error Message
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            // Create Button
            Section {
                Button {
                    Task {
                        await createBill()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isCreating {
                            ProgressView()
                        } else {
                            Text("Create Bill")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(!canCreate || isCreating)
            }
        }
        .task {
            await friendsViewModel.loadFriends()
        }
    }

    private func createBill() async {
        isCreating = true
        errorMessage = nil

        do {
            let participantIds = Array(selectedParticipants)
            let billItems = items.map { item in
                BillItem(id: nil, name: item.name, quantity: item.quantity, cost: item.price)
            }

            let response = try await APIService.shared.createManualBill(
                restaurantName: restaurantName,
                participants: participantIds,
                items: billItems
            )

            // Set assignment mode
            _ = try await APIService.shared.setAssignmentMode(
                billId: response.data.id,
                mode: assignmentMode
            )

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isCreating = false
    }
}

struct ManualBillItem: Identifiable {
    let id = UUID()
    var name: String = ""
    var quantity: Int = 1
    var price: Double = 0.0
}

#Preview {
    ManualEntryView()
}
