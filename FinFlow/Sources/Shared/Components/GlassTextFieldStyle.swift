import SwiftUI

public struct GlassTextFieldStyle: TextFieldStyle {
    public init() {}
    
    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(Theme.Typography.body)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            // Liquid Glass effect
            .glassEffectWithFallback(fallbackMaterial: .ultraThinMaterial, interactive: true)
            // Subtle transition when focused
            .animation(.easeOut(duration: 0.2), value: true) // TextField state might trigger this, but focus state is handled best via @FocusState in the parent view. This handles intrinsic animations.
    }
}

public extension TextFieldStyle where Self == GlassTextFieldStyle {
    /// A premium liquid glass style for text fields.
    static var glass: GlassTextFieldStyle {
        GlassTextFieldStyle()
    }
}
