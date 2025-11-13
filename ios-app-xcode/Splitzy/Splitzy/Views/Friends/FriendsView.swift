import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()
    @State private var showAddFriend = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.friends.isEmpty {
                    ProgressView("Loading friends...")
                } else if viewModel.friends.isEmpty {
                    ContentUnavailableView(
                        "No Friends Yet",
                        systemImage: "person.2",
                        description: Text("Add friends to start splitting bills together")
                    )
                } else {
                    List {
                        ForEach(viewModel.friends, id: \.id) { friend in
                            FriendRowView(friend: friend)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let friend = viewModel.friends[index]
                                Task {
                                    await viewModel.removeFriend(friend)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await viewModel.loadFriends()
                    }
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddFriend = true
                    } label: {
                        Image(systemName: "person.badge.plus")
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

struct FriendRowView: View {
    let friend: User

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.headline)

                Text(friend.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Preferences badges
                HStack(spacing: 6) {
                    let prefs = friend.preferences

                    if !prefs.drinksAlcohol {
                        PreferenceBadge(icon: "wineglass.fill", text: "No alcohol", color: .orange)
                    }

                    if !prefs.eatsMeat {
                        PreferenceBadge(icon: "leaf.fill", text: "Vegetarian", color: .green)
                    } else if !prefs.meatTypes.isEmpty {
                        PreferenceBadge(icon: "fork.knife", text: "\(prefs.meatTypes.count) meats", color: .brown)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct PreferenceBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.2))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

#Preview {
    FriendsView()
}
