import SwiftUI

public struct GlassTextField: View {
    public var title: String
    public var placeholder: String
    @Binding public var text: String
    
    public init(title: String, placeholder: String, text: Binding<String>) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(Theme.Typography.caption1)
                .secondaryTextColor()
                .padding(.leading, 4)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.glass)
        }
    }
}
