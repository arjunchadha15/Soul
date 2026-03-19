import SwiftUI
import PhotosUI

struct NewUpdateView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    let project: Project
    var onCreated: (ProjectUpdate) -> Void

    @State private var text = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var mediaData: Data?
    @State private var mediaImage: Image?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let service = UpdateService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.soulBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Project context
                        HStack {
                            Text(project.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.soulAccent)
                            Spacer()
                        }

                        // Text input
                        ZStack(alignment: .topLeading) {
                            if text.isEmpty {
                                Text("What's the update?")
                                    .foregroundStyle(Color.soulTextSecondary.opacity(0.5))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                            }
                            TextEditor(text: $text)
                                .frame(minHeight: 120)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .scrollContentBackground(.hidden)
                                .foregroundStyle(Color.soulTextPrimary)
                        }
                        .background(Color.soulCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Photo picker
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            if let image = mediaImage {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(alignment: .topTrailing) {
                                        Button {
                                            selectedPhotoItem = nil
                                            mediaData = nil
                                            mediaImage = nil
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.white)
                                                .padding(8)
                                        }
                                    }
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "photo")
                                    Text("Add Photo")
                                }
                                .font(.subheadline)
                                .foregroundStyle(Color.soulTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.soulCard)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .onChange(of: selectedPhotoItem) { loadMedia() }

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        SoulButton(
                            title: "Post Update",
                            action: postUpdate,
                            isLoading: isLoading,
                            isDisabled: text.isBlank && mediaData == nil
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("New Update")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.soulTextSecondary)
                }
            }
        }
    }

    private func loadMedia() {
        Task {
            if let item = selectedPhotoItem,
               let data = try? await item.loadTransferable(type: Data.self) {
                mediaData = data
                if let uiImage = UIImage(data: data) {
                    mediaImage = Image(uiImage: uiImage)
                }
            }
        }
    }

    private func postUpdate() {
        guard let userId = authService.currentUser?.id else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let update = try await service.createUpdate(
                    projectId: project.id,
                    userId: userId,
                    text: text.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                onCreated(update)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
