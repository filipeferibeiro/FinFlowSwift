import SwiftUI

public struct AdaptiveContainerModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let maxWidth: Double
    let applyHorizontalPadding: Bool

    public init(maxWidth: Double = Theme.Layout.maxDashboardWidth, applyHorizontalPadding: Bool = true) {
        self.maxWidth = maxWidth
        self.applyHorizontalPadding = applyHorizontalPadding
    }

    public func body(content: Content) -> some View {
        let isRegular = horizontalSizeClass == .regular
        let horizontalPadding = isRegular
            ? Theme.Layout.regularHorizontalPadding
            : Theme.Layout.compactHorizontalPadding

        content
            .padding(.horizontal, applyHorizontalPadding ? horizontalPadding : 0)
            .frame(maxWidth: isRegular ? maxWidth : .infinity)
            .frame(maxWidth: .infinity)
    }
}

public extension View {
    func adaptiveContainer(
        maxWidth: Double = Theme.Layout.maxDashboardWidth,
        applyHorizontalPadding: Bool = true
    ) -> some View {
        modifier(AdaptiveContainerModifier(maxWidth: maxWidth, applyHorizontalPadding: applyHorizontalPadding))
    }
}
