import SwiftUI

public struct ParticleDustEffect: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    public init() {}

    public var body: some View {
        if !reduceMotion {
            GeometryReader { geo in
                ZStack {
                    ForEach(0..<35, id: \.self) { index in
                        let size = Double.random(in: 2...5)
                        let startX = Double.random(in: 0...max(1, geo.size.width))
                        let startY = Double.random(in: 0...max(1, geo.size.height))

                        let targetX = startX + Double.random(in: 40...250)
                        let targetY = startY + Double.random(in: -150...100)
                        let delay = Double.random(in: 0...0.3)

                        Circle()
                            .fill(index.isMultiple(of: 3) ? Theme.Colors.primary : Theme.Colors.textSecondary)
                            .frame(width: size, height: size)
                            .position(x: animate ? targetX : startX, y: animate ? targetY : startY)
                            .scaleEffect(animate ? 0.1 : 1.0)
                            .opacity(animate ? 0.0 : 1.0)
                            .animation(.easeOut(duration: 0.5).delay(delay), value: animate)
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                animate = true
            }
        }
    }
}
