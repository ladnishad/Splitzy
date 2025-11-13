import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()

    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // User Info Section
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(authViewModel.currentUser?.name ?? "")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 8)
                }

                // Dietary Preferences
                Section {
                    Toggle(isOn: $viewModel.drinksAlcohol) {
                        Label("Drinks Alcohol", systemImage: "wineglass")
                    }

                    Toggle(isOn: $viewModel.eatsMeat) {
                        Label("Eats Meat", systemImage: "fork.knife")
                    }

                    // Meat Types (shown only if eats meat)
                    if viewModel.eatsMeat {
                        NavigationLink {
                            MeatTypesSelectionView(selectedMeatTypes: $viewModel.selectedMeatTypes)
                        } label: {
                            HStack {
                                Label("Meat Preferences", systemImage: "list.bullet")

                                Spacer()

                                if viewModel.selectedMeatTypes.isEmpty {
                                    Text("All")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("\(viewModel.selectedMeatTypes.count) selected")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Dietary Preferences")
                } footer: {
                    Text("These preferences help split bills more accurately based on what you consume")
                }

                // Actions Section
                Section {
                    Button {
                        Task {
                            await viewModel.savePreferences()
                        }
                    } label: {
                        if viewModel.isSaving {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Save Preferences")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(viewModel.isSaving || !viewModel.hasChanges)

                    Button(role: .destructive) {
                        showLogoutAlert = true
                    } label: {
                        Text("Log Out")
                            .frame(maxWidth: .infinity)
                    }
                }

                if let successMessage = viewModel.successMessage {
                    Section {
                        Text(successMessage)
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    authViewModel.logout()
                }
            } message: {
                Text("Are you sure you want to log out?")
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
            .onAppear {
                viewModel.loadPreferences(from: authViewModel.currentUser)
            }
        }
    }
}

struct MeatTypesSelectionView: View {
    @Binding var selectedMeatTypes: Set<String>

    var body: some View {
        List {
            ForEach(MeatType.allCases) { meatType in
                Button {
                    if selectedMeatTypes.contains(meatType.rawValue) {
                        selectedMeatTypes.remove(meatType.rawValue)
                    } else {
                        selectedMeatTypes.insert(meatType.rawValue)
                    }
                } label: {
                    HStack {
                        Text(meatType.displayName)
                            .foregroundStyle(.primary)

                        Spacer()

                        if selectedMeatTypes.contains(meatType.rawValue) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Meat Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
