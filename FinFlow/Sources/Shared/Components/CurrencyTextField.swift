import SwiftUI

public struct CurrencyTextField: View {
    @Binding var valueInCents: Int
    @State private var text: String = ""

    public init(valueInCents: Binding<Int>) {
        self._valueInCents = valueInCents
    }

    public var body: some View {
        TextField("0,00", text: $text)
            .keyboardType(.numberPad)
            .onChange(of: text) { _, newValue in
                let cleanString = newValue.filter(\.isWholeNumber)

                if let cents = Int(cleanString), cents > 0 {
                    if valueInCents != cents {
                        valueInCents = cents
                    }
                    let formatted = CurrencyFormatter.formatDecimal(cents)
                    if text != formatted {
                        text = formatted
                    }
                } else {
                    if valueInCents != 0 {
                        valueInCents = 0
                    }
                    if !text.isEmpty {
                        text = ""
                    }
                }
            }
            .onChange(of: valueInCents, initial: true) { _, newValue in
                if newValue > 0 {
                    let formatted = CurrencyFormatter.formatDecimal(newValue)
                    if text != formatted {
                        text = formatted
                    }
                } else if !text.isEmpty {
                    text = ""
                }
            }
    }
}
