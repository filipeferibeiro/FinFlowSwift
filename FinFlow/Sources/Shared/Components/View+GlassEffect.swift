import SwiftUI

public extension View {
    @ViewBuilder
    func glassEffectWithFallback<S: Shape>(
        in shape: S,
        fallbackMaterial: Material = .ultraThinMaterial,
        interactive: Bool = false
    ) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
                .overlay(
                    shape.stroke(
                        LinearGradient(colors: [.white.opacity(0.4), .clear, .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1
                    )
                )
                .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
        } else {
            self.background(fallbackMaterial, in: shape)
                .overlay(
                    shape.stroke(
                        LinearGradient(colors: [.white.opacity(0.4), .clear, .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1
                    )
                )
                .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
        }
    }
    
    @ViewBuilder
    func glassEffectWithFallback(
        fallbackMaterial: Material = .ultraThinMaterial,
        interactive: Bool = false
    ) -> some View {
        glassEffectWithFallback(in: RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius, style: .continuous), fallbackMaterial: fallbackMaterial, interactive: interactive)
    }
    
    @ViewBuilder
    func prominentGlassEffectWithFallback<S: Shape>(
        in shape: S,
        fallbackMaterial: Material = .regularMaterial,
        interactive: Bool = false
    ) -> some View {
        glassEffectWithFallback(in: shape, fallbackMaterial: fallbackMaterial, interactive: interactive)
    }
    
    @ViewBuilder
    func prominentGlassEffectWithFallback(
        fallbackMaterial: Material = .regularMaterial,
        interactive: Bool = false
    ) -> some View {
        glassEffectWithFallback(in: RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius, style: .continuous), fallbackMaterial: fallbackMaterial, interactive: interactive)
    }
}

public struct FallbackGlassContainer<Content: View>: View {
    let spacing: CGFloat?
    let content: Content
    
    public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    public var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            if let spacing = spacing {
                VStack(spacing: spacing) {
                    content
                }
            } else {
                content
            }
        }
    }
}

