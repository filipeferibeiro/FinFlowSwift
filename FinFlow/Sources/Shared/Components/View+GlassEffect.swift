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
                .overlay {
                    shape.stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .clear, .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                }
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
        } else {
            self.background(fallbackMaterial, in: shape)
                .overlay {
                    shape.stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .clear, .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                }
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
        }
    }

    @ViewBuilder
    func glassEffectWithFallback(
        fallbackMaterial: Material = .ultraThinMaterial,
        interactive: Bool = false
    ) -> some View {
        glassEffectWithFallback(
            in: RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius),
            fallbackMaterial: fallbackMaterial,
            interactive: interactive
        )
    }

    @ViewBuilder
    func prominentGlassEffectWithFallback<S: Shape>(
        in shape: S,
        tint: Color = Theme.Colors.primary,
        interactive: Bool = false
    ) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(
                interactive ? .regular.tint(tint).interactive() : .regular.tint(tint),
                in: shape
            )
            .shadow(color: tint.opacity(0.3), radius: 12, x: 0, y: 6)
        } else {
            self.background(tint.gradient, in: shape)
                .overlay {
                    shape.stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .clear, .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                }
                .shadow(color: tint.opacity(0.3), radius: 12, x: 0, y: 6)
        }
    }

    @ViewBuilder
    func prominentGlassEffectWithFallback(
        tint: Color = Theme.Colors.primary,
        interactive: Bool = false
    ) -> some View {
        prominentGlassEffectWithFallback(
            in: RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius),
            tint: tint,
            interactive: interactive
        )
    }
}
