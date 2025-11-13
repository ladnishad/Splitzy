import SwiftUI
import PhotosUI

struct UploadBillView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var friendsViewModel = FriendsViewModel()

    @State private var selectedImage: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var restaurantName = ""
    @State private var restaurantType: RestaurantType = .restaurant
    @State private var selectedParticipants: Set<String> = []
    @State private var isUploading = false
    @State private var errorMessage: String?

    var canUpload: Bool {
        imageData != nil && !restaurantName.isEmpty && !selectedParticipants.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Image Picker Section
                Section {
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        if let imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                        } else {
                            Label("Select Bill Image", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        }
                    }
                } header: {
                    Text("Bill Image")
                }

                // Restaurant Details
                Section("Restaurant Details") {
                    TextField("Restaurant Name", text: $restaurantName)

                    Picker("Type", selection: $restaurantType) {
                        Text("Restaurant").tag(RestaurantType.restaurant)
                        Text("Bar").tag(RestaurantType.bar)
                    }
                    .pickerStyle(.segmented)
                }

                // Participants Section
                Section {
                    if friendsViewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if friendsViewModel.friends.isEmpty {
                        ContentUnavailableView(
                            "No Friends",
                            systemImage: "person.2.slash",
                            description: Text("Add friends to split bills with them")
                        )
                    } else {
                        ForEach(friendsViewModel.friends, id: \.id) { friend in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(.blue)

                                VStack(alignment: .leading) {
                                    Text(friend.name)
                                        .font(.body)
                                    Text(friend.email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

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
                    Text("Select Participants")
                } footer: {
                    Text("You will be automatically added as a participant")
                }

                // Error Message
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Upload Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Upload") {
                        Task {
                            await uploadBill()
                        }
                    }
                    .disabled(!canUpload || isUploading)
                }
            }
            .task {
                await friendsViewModel.loadFriends()
            }
            .onChange(of: selectedImage) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
            }
        }
    }

    private func uploadBill() async {
        guard let imageData else { return }

        isUploading = true
        errorMessage = nil

        do {
            let participantIds = Array(selectedParticipants)
            _ = try await APIService.shared.uploadBill(
                image: imageData,
                participants: participantIds,
                restaurantName: restaurantName,
                restaurantType: restaurantType.rawValue
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isUploading = false
    }
}

#Preview {
    UploadBillView()
}
