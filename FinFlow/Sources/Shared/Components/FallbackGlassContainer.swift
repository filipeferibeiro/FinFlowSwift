import SwiftUI

public struct FallbackGlassContainer<Content: View>: View {
    let spacing: CGFloat?
    @ViewBuilder let content: Content

    public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else if let spacing {
            VStack(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}
