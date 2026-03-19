import SwiftUI
import PhotosUI

struct NewProjectView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    var onCreated: (Project) -> Void

    @State private var title = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var coverImageData: Data?
    @State private var coverImage: Image?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let service = ProjectService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.soulBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Cover photo picker
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            coverPickerLabel
                        }
                        .onChange(of: selectedPhotoItem) {
                            loadCoverImage()
                        }

                        // Form fields
                        VStack(spacing: 12) {
                            SoulTextField(
                                placeholder: "Project Title",
                                text: $title,
                                autocapitalization: .words
                            )

                            ZStack(alignment: .topLeading) {
                                if description.isEmpty {
                                    Text("Description (optional)")
                                        .foregroundStyle(Color.soulTextSecondary.opacity(0.5))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                }
                                TextEditor(text: $description)
                                    .frame(minHeight: 100)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .scrollContentBackground(.hidden)
                                    .foregroundStyle(Color.soulTextPrimary)
                            }
                            .background(Color.soulCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            DatePicker(
                                "Start Date",
                                selection: $startDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.soulCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .tint(Color.soulAccent)
                            .foregroundStyle(Color.soulTextPrimary)
                            .colorScheme(.dark)
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }

                        SoulButton(
                            title: "Create Project",
                            action: createProject,
                            isLoading: isLoading,
                            isDisabled: title.isBlank
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.soulTextSecondary)
                }
            }
        }
    }

    private var coverPickerLabel: some View {
        ZStack {
            if let image = coverImage {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.soulCard)
                    .frame(height: 120)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "camera")
                                .font(.title2)
                                .foregroundStyle(Color.soulTextSecondary)
                            Text("Add Cover Photo")
                                .font(.subheadline)
                                .foregroundStyle(Color.soulTextSecondary)
                        }
                    }
            }
        }
    }

    private func loadCoverImage() {
        Task {
            if let item = selectedPhotoItem,
               let data = try? await item.loadTransferable(type: Data.self) {
                coverImageData = data
                if let uiImage = UIImage(data: data) {
                    coverImage = Image(uiImage: uiImage)
                }
            }
        }
    }

    private func createProject() {
        guard let userId = authService.currentUser?.id else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let project = try await service.createProject(
                    userId: userId,
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                    startDate: startDate,
                    coverImageUrl: nil
                )
                onCreated(project)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
