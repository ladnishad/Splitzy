import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = FriendsViewModel()

    @State private var searchEmail = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search by email", text: $searchEmail)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .submitLabel(.search)
                        .onSubmit {
                            Task {
                                await viewModel.searchUsers(email: searchEmail)
                            }
                        }

                    if !searchEmail.isEmpty {
                        Button {
                            searchEmail = ""
                            viewModel.searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()

                // Search Results
                if viewModel.isSearching {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if searchEmail.isEmpty {
                    ContentUnavailableView(
                        "Search for Friends",
                        systemImage: "person.2.fill",
                        description: Text("Enter an email address to find and add friends")
                    )
                } else if viewModel.searchResults.isEmpty {
                    ContentUnavailableView(
                        "No Users Found",
                        systemImage: "person.fill.questionmark",
                        description: Text("No users found with email '\(searchEmail)'")
                    )
                } else {
                    List {
                        ForEach(viewModel.searchResults, id: \.id) { user in
                            HStack(spacing: 12) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.blue)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.name)
                                        .font(.headline)

                                    Text(user.email)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button {
                                    Task {
                                        await addFriend(user)
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(.plain)
                }

                Spacer()
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Friend Added", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Friend has been added to your list")
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

    private func addFriend(_ user: User) async {
        await viewModel.addFriend(email: user.email)

        if viewModel.errorMessage == nil {
            showSuccess = true
        }
    }
}

#Preview {
    AddFriendView()
}
