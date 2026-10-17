import SwiftUI

public enum Theme {
    public enum Colors {
        // Executive Royal Blue Brand Palette (Zero Pastels)
        public static let primary = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "#3B7BFF")) // Electric Royal Blue
                : UIColor(Color(hex: "#1A5CFF")) // Institutional Royal Blue
        })

        public static let primaryDeep = Color(hex: "#0D2B6B")
        public static let secondaryAccent = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "#38BDF8")) // Vibrant Sky Cyan
                : UIColor(Color(hex: "#0096E6")) // Deep Ocean Cyan
        })

        public static let primaryGradient = LinearGradient(
            colors: [Color(hex: "#1A5CFF"), Color(hex: "#0088FF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        public static let heroGradient = LinearGradient(
            colors: [
                Color(hex: "#0B1F52"),
                Color(hex: "#1545C7"),
                Color(hex: "#1A6BFF")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Backgrounds (Deep Midnight Navy for dark mode, Crisp Ice Slate for light mode)
        public static let backgroundBase = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "#060A12"))
                : UIColor(Color(hex: "#F2F5FA"))
        })

        // Solid Surfaces
        public static let surfaceSolid = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "#101726"))
                : UIColor(Color(hex: "#FFFFFF"))
        })

        public static let surfaceElevated = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "#182236"))
                : UIColor(Color(hex: "#E8EEF7"))
        })

        public static let cardBorder = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(Color.white.opacity(0.10))
                : UIColor(Color(hex: "#1A5CFF").opacity(0.10))
        })

        // Typography
        public static let textPrimary = Color.primary
        public static let textSecondary = Color.secondary
        public static let textTertiary = Color(UIColor.tertiaryLabel)

        // Vibrant, High-Contrast Financial Semantics (No Pastels)
        public static let success = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "#10B981")) // Vibrant Emerald
                : UIColor(Color(hex: "#059669")) // Deep Emerald
        })

        public static let error = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "#F43F5E")) // Vibrant Crimson Rose
                : UIColor(Color(hex: "#DC2626")) // Deep Crimson
        })

        public static let warning = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "#F59E0B")) // Vibrant Amber
                : UIColor(Color(hex: "#D97706")) // Rich Amber
        })
    }

    public enum Typography {
        // Dynamic Type-compliant executive typography
        public static let hero = Font.system(.largeTitle, design: .rounded).bold()
        public static let largeTitle = Font.system(.largeTitle, design: .rounded).bold()
        public static let title1 = Font.system(.title, design: .rounded).bold()
        public static let title2 = Font.system(.title2, design: .rounded).weight(.semibold)
        public static let title3 = Font.system(.title3, design: .rounded).weight(.semibold)

        public static let headline = Font.system(.headline, design: .default).weight(.semibold)
        public static let body = Font.system(.body, design: .default)
        public static let subheadline = Font.system(.subheadline, design: .default).weight(.medium)

        public static let caption1 = Font.system(.caption, design: .default).weight(.semibold)
        public static let caption2 = Font.system(.caption2, design: .default).weight(.semibold)
    }

    public enum Layout {
        public static let standardPadding: Double = 20
        public static let cornerRadius: Double = 16
        public static let cardCornerRadius: Double = 24
        public static let buttonCornerRadius: Double = 16
    }
}

public extension View {
    func primaryTextColor() -> some View {
        self.foregroundStyle(Theme.Colors.textPrimary)
    }

    func secondaryTextColor() -> some View {
        self.foregroundStyle(Theme.Colors.textSecondary)
    }

    func surfaceBackground() -> some View {
        self.background(
            RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
