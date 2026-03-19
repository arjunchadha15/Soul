import SwiftUI

struct SoulTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.soulCard)
        .foregroundStyle(Color.soulTextPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .tint(Color.soulAccent)
    }
}
