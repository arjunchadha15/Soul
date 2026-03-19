import SwiftUI

struct StatusBadge: View {
    let status: ProjectStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.18))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch status {
        case .active: return .green
        case .paused: return .orange
        case .completed: return Color.soulAccent
        }
    }
}

#Preview {
    HStack {
        StatusBadge(status: .active)
        StatusBadge(status: .paused)
        StatusBadge(status: .completed)
    }
    .padding()
    .background(Color.soulBackground)
}
