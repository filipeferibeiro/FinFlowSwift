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
            .onChange(of: text) { oldValue, newValue in
                // Remove everything that is not a number
                let cleanString = newValue.filter { $0.isWholeNumber }
                
                if let cents = Int(cleanString) {
                    valueInCents = cents
                    text = format(cents: cents)
                } else {
                    valueInCents = 0
                    text = "" // Allows showing placeholder if empty, but for currency usually we show 0,00
                }
            }
            .onAppear {
                if valueInCents > 0 {
                    text = format(cents: valueInCents)
                }
            }
    }
    
    private func format(cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = "."
        
        let doubleValue = Double(cents) / 100.0
        return formatter.string(from: NSNumber(value: doubleValue)) ?? "0,00"
    }
}
