import SwiftUI

struct SoulButton: View {
    let title: String
    let action: () -> Void
    var style: ButtonStyle = .primary
    var isLoading = false
    var isDisabled = false

    enum ButtonStyle {
        case primary, secondary, ghost
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(style == .primary ? Color.soulBackground : Color.soulAccent)
                        .scaleEffect(0.8)
                }
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(background)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                if style == .secondary {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.soulAccent.opacity(0.4), lineWidth: 1)
                }
            }
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1)
    }

    private var background: Color {
        switch style {
        case .primary: return Color.soulAccent
        case .secondary: return Color.soulCard
        case .ghost: return .clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return Color.soulBackground
        case .secondary, .ghost: return Color.soulAccent
        }
    }
}
