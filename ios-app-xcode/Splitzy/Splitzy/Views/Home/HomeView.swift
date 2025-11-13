import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = BillsViewModel()
    @State private var showUploadBill = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle gradient background
                LinearGradient(
                    colors: [Color(.systemBackground), Color.blue.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if viewModel.isLoading && viewModel.bills.isEmpty {
                    ProgressView("Loading bills...")
                } else if viewModel.bills.isEmpty {
                    ContentUnavailableView(
                        "No Bills Yet",
                        systemImage: "doc.text",
                        description: Text("Upload your first bill to get started")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.bills) { bill in
                                NavigationLink {
                                    BillDetailView(bill: bill)
                                } label: {
                                    BillCardView(bill: bill)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.loadBills()
                    }
                }
            }
            .navigationTitle("Bills")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showUploadBill = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 36, height: 36)

                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showUploadBill) {
                UploadBillView()
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

struct BillCardView: View {
    let bill: Bill

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with restaurant name and amount
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(bill.restaurant.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Label(
                        bill.restaurant.type.displayName,
                        systemImage: bill.restaurant.type == .bar ? "wineglass" : "fork.knife"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(bill.totalAmount, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text(bill.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(statusColor(for: bill.status).opacity(0.15))
                        .foregroundStyle(statusColor(for: bill.status))
                        .clipShape(Capsule())
                }
            }

            // Divider
            Rectangle()
                .fill(.ultraThinMaterial)
                .frame(height: 1)

            // Participants info
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(bill.participants.count) participants")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
        )
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
