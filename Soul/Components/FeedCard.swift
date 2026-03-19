import SwiftUI

struct FeedCard: View {
    let item: FeedItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: user + project
            HStack(spacing: 10) {
                AvatarView(url: item.user.avatarUrl, size: 38, name: item.user.fullName)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.user.fullName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.soulTextPrimary)

                    Text(item.project.title)
                        .font(.caption)
                        .foregroundStyle(Color.soulAccent)
                }

                Spacer()

                Text(item.update.createdAt.relativeFormatted())
                    .font(.caption2)
                    .foregroundStyle(Color.soulTextSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider()
                .background(Color.white.opacity(0.06))

            // Media
            if let mediaUrl = item.update.mediaUrl,
               item.update.mediaType == .photo,
               let url = URL(string: mediaUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle()
                            .fill(Color.soulAccent.opacity(0.06))
                            .frame(height: 200)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()
            }

            // Update text
            if !item.update.text.isEmpty {
                Text(item.update.text)
                    .font(.body)
                    .foregroundStyle(Color.soulTextPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
            }
        }
        .cardStyle()
    }
}
