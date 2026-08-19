import SwiftUI

public enum Theme {
    public enum Colors {
        // Premium Brand Colors (Pastel Tones)
        public static let primary = Color(hex: "#FFB380") // Soft Pastel Orange
        public static let primaryGradient = LinearGradient(
            colors: [Color(hex: "#FFB380"), Color(hex: "#FFD5B3")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let secondaryAccent = Color(hex: "#FFDAC1") // Pastel Peach
        
        // Backgrounds (Deep and immersive for dark mode, crisp for light mode)
        public static let backgroundBase = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#0A0A0C")) : UIColor(Color(hex: "#F8F9FA"))
        })
        
        // Surfaces are meant to be materials, but if a solid is needed:
        public static let surfaceSolid = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#1C1C1E")) : UIColor(Color(hex: "#FFFFFF"))
        })
        
        // Typography
        public static let textPrimary = Color.primary
        public static let textSecondary = Color.secondary
        public static let textTertiary = Color(UIColor.tertiaryLabel)
        
        // Semantics - Dynamic colors for better contrast in light/dark modes
        public static let success = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#72E385")) : UIColor(Color(hex: "#2B9348"))
        })
        public static let error = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#FF8FAB")) : UIColor(Color(hex: "#D90429"))
        })
        public static let warning = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#FFD166")) : UIColor(Color(hex: "#E07A5F"))
        })
    }
    
    public enum Typography {
        // Modern, sophisticated typography sizes
        public static let hero = Font.system(size: 48, weight: .bold, design: .rounded)
        public static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
        public static let title1 = Font.system(.title, design: .default).weight(.bold)
        public static let title2 = Font.system(.title2, design: .default).weight(.semibold)
        public static let title3 = Font.system(.title3, design: .default).weight(.medium)
        
        public static let headline = Font.system(.headline, design: .default).weight(.semibold)
        public static let body = Font.system(.body, design: .default).weight(.regular)
        public static let subheadline = Font.system(.subheadline, design: .default).weight(.regular)
        
        public static let caption1 = Font.system(.caption, design: .default).weight(.medium)
        public static let caption2 = Font.system(.caption2, design: .default).weight(.medium)
    }
    
    public enum Layout {
        public static let standardPadding: CGFloat = 20
        public static let cornerRadius: CGFloat = 16
        public static let cardCornerRadius: CGFloat = 24
        public static let buttonCornerRadius: CGFloat = 16
    }
}

// Custom Glass Component for Premium Aesthetics
public struct PremiumGlassContainer<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let cornerRadius: CGFloat
    let padding: CGFloat
    let content: Content
    
    public init(cornerRadius: CGFloat = Theme.Layout.cardCornerRadius, padding: CGFloat = Theme.Layout.standardPadding, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(padding)
            .glassEffectWithFallback(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// Fallback extension for legacy compatibility within the app
public extension View {
    func primaryTextColor() -> some View {
        self.foregroundStyle(Theme.Colors.textPrimary)
    }
    func secondaryTextColor() -> some View {
        self.foregroundStyle(Theme.Colors.textSecondary)
    }
    func surfaceBackground() -> some View {
        self.background(
            RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius, style: .continuous)
                .fill(Theme.Colors.surfaceSolid)
        )
    }
}

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
