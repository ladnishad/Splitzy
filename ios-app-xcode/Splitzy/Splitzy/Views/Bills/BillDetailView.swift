import SwiftUI

struct BillDetailView: View {
    let bill: Bill
    @State private var showDeleteAlert = false
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
                // Handle delete
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this bill? This action cannot be undone.")
        }
    }
}
