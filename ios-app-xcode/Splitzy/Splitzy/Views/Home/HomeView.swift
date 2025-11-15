import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = BillsViewModel()
    @State private var showUploadBill = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.bills.isEmpty {
                    ProgressView("Loading bills...")
                } else if viewModel.bills.isEmpty {
                    ContentUnavailableView(
                        "No Bills Yet",
                        systemImage: "doc.text",
                        description: Text("Add your first bill to get started")
                    )
                } else {
                    List {
                        ForEach(viewModel.bills) { bill in
                            NavigationLink {
                                BillDetailView(bill: bill)
                            } label: {
                                BillRowView(bill: bill)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await viewModel.loadBills()
                    }
                }
            }
            .navigationTitle("Bills")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showUploadBill = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showUploadBill) {
                CreateBillView()
                    .onDisappear {
                        Task {
                            await viewModel.loadBills()
                        }
                    }
            }
            .task {
                await viewModel.loadBills()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
}

struct BillRowView: View {
    let bill: Bill

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(bill.restaurant.name)
                    .font(.headline)

                Spacer()

                Text("$\(bill.totalAmount, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundStyle(.blue)
            }

            HStack {
                Label(bill.restaurant.type.displayName, systemImage: bill.restaurant.type == .bar ? "wineglass" : "fork.knife")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(bill.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: bill.status).opacity(0.2))
                    .foregroundStyle(statusColor(for: bill.status))
                    .clipShape(Capsule())
            }

            HStack {
                Image(systemName: "person.2.fill")
                    .font(.caption2)
                Text("\(bill.participants.count) participants")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    func statusColor(for status: BillStatus) -> Color {
        switch status {
        case .uploaded: return .orange
        case .processing: return .blue
        case .processed: return .green
        case .split: return .purple
        }
    }
}

#Preview {
    HomeView()
}
