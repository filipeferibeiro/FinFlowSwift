import SwiftUI

public extension View {
    @ViewBuilder
    func glassEffectWithFallback<S: Shape>(
        in shape: S,
        fallbackMaterial: Material = .ultraThinMaterial,
        interactive: Bool = false
    ) -> some View {
        if #available(iOS 26, *) {
            self.contentShape(shape)
                .glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
                .overlay {
                    shape.stroke(Theme.Colors.cardBorder, lineWidth: 1)
                        .allowsHitTesting(false)
                }
                .contentShape(shape)
                .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 6)
        } else {
            self.contentShape(shape)
                .background(fallbackMaterial, in: shape)
                .overlay {
                    shape.stroke(Theme.Colors.cardBorder, lineWidth: 1)
                        .allowsHitTesting(false)
                }
                .contentShape(shape)
                .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 6)
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
            self.contentShape(shape)
                .glassEffect(
                    interactive ? .regular.tint(tint).interactive() : .regular.tint(tint),
                    in: shape
                )
                .contentShape(shape)
                .shadow(color: tint.opacity(0.32), radius: 14, x: 0, y: 6)
        } else {
            self.contentShape(shape)
                .background(tint.gradient, in: shape)
                .overlay {
                    shape.stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .clear, .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .allowsHitTesting(false)
                }
                .contentShape(shape)
                .shadow(color: tint.opacity(0.32), radius: 14, x: 0, y: 6)
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
