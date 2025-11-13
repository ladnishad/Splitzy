import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()
    @State private var showAddFriend = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [Color(.systemBackground), Color.purple.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if viewModel.isLoading && viewModel.friends.isEmpty {
                    ProgressView("Loading friends...")
                } else if viewModel.friends.isEmpty {
                    ContentUnavailableView(
                        "No Friends Yet",
                        systemImage: "person.2",
                        description: Text("Add friends to start splitting bills together")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.friends, id: \.id) { friend in
                                FriendCardView(friend: friend) {
                                    Task {
                                        await viewModel.removeFriend(friend)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.loadFriends()
                    }
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddFriend = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 36, height: 36)

                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.purple)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddFriend) {
                AddFriendView()
                    .onDisappear {
                        Task {
                            await viewModel.loadFriends()
                        }
                    }
            }
            .task {
                await viewModel.loadFriends()
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

struct FriendCardView: View {
    let friend: User
    let onDelete: () -> Void
    @State private var showDeleteAlert = false

    var body: some View {
        HStack(spacing: 16) {
            // Avatar with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)

                Text(String(friend.name.prefix(1)).uppercased())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(friend.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(friend.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Preferences badges
                HStack(spacing: 6) {
                    let prefs = friend.preferences

                    if !prefs.drinksAlcohol {
                        ModernBadge(icon: "wineglass.fill", text: "No alcohol", color: .orange)
                    }

                    if !prefs.eatsMeat {
                        ModernBadge(icon: "leaf.fill", text: "Vegetarian", color: .green)
                    } else if !prefs.meatTypes.isEmpty {
                        ModernBadge(icon: "fork.knife", text: "\(prefs.meatTypes.count) meats", color: .brown)
                    }
                }
            }

            Spacer()

            // Delete button
            Button {
                showDeleteAlert = true
            } label: {
                Image(systemName: "trash.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
        )
        .alert("Remove Friend", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to remove \(friend.name) from your friends?")
        }
    }
}

struct ModernBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
            Text(text)
                .font(.system(size: 9, weight: .medium))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            ZStack {
                color.opacity(0.15)
                .blur(radius: 2)

                color.opacity(0.1)
            }
        )
        .foregroundStyle(color)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(color.opacity(0.2), lineWidth: 0.5)
        )
    }
}

#Preview {
    FriendsView()
}
