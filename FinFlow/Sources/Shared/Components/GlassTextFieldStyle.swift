import SwiftUI

public struct GlassTextFieldStyle: TextFieldStyle {
    public init() {}

    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(Theme.Typography.body)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .glassEffectWithFallback(fallbackMaterial: .ultraThinMaterial, interactive: true)
    }
}

public extension TextFieldStyle where Self == GlassTextFieldStyle {
    /// A premium liquid glass style for text fields.
    static var glass: GlassTextFieldStyle {
        GlassTextFieldStyle()
    }
}
