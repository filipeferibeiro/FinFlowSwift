import SwiftUI

public struct GradientBackground: View {
    @State private var isAnimating = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Theme.Colors.backgroundBase
                .ignoresSafeArea()
            
            GeometryReader { proxy in
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.12))
                        .frame(width: proxy.size.width * 1.5)
                        .blur(radius: 80)
                        .offset(x: isAnimating ? proxy.size.width * 0.1 : -proxy.size.width * 0.2,
                                y: isAnimating ? -proxy.size.height * 0.1 : proxy.size.height * 0.2)
                    
                    Circle()
                        .fill(Theme.Colors.secondaryAccent.opacity(0.1))
                        .frame(width: proxy.size.width * 1.2)
                        .blur(radius: 100)
                        .offset(x: isAnimating ? -proxy.size.width * 0.2 : proxy.size.width * 0.3,
                                y: isAnimating ? proxy.size.height * 0.4 : -proxy.size.height * 0.1)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    Group {
        GradientBackground()
            .preferredColorScheme(.light)
        
        GradientBackground()
            .preferredColorScheme(.dark)
    }
}
