import SwiftUI

public struct FloatingActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    public init(
        title: String = "Nova Transação",
        systemImage: String = "plus",
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .prominentGlassEffectWithFallback(in: .circle, interactive: true)
        }
        .accessibilityLabel(title)
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}
