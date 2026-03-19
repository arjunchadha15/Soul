import SwiftUI

struct ProjectCard: View {
    let project: Project
    var showStatus = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cover image
            if let coverUrl = project.coverImageUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle()
                            .fill(Color.soulAccent.opacity(0.08))
                    }
                }
                .frame(height: 140)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(project.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.soulTextPrimary)
                        .lineLimit(2)

                    Spacer()

                    if showStatus {
                        StatusBadge(status: project.status)
                    }
                }

                if !project.description.isEmpty {
                    Text(project.description)
                        .font(.subheadline)
                        .foregroundStyle(Color.soulTextSecondary)
                        .lineLimit(2)
                }

                Text("Started \(project.startDate.formatted())")
                    .font(.caption)
                    .foregroundStyle(Color.soulTextSecondary.opacity(0.7))
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .padding(12)
        .cardStyle()
    }
}
