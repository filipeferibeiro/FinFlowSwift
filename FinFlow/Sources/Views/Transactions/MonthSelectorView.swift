import SwiftUI

public struct MonthSelectorView: View {
    let selectedDate: Date
    let onChangeMonth: (Int) -> Void

    public init(selectedDate: Date, onChangeMonth: @escaping (Int) -> Void) {
        self.selectedDate = selectedDate
        self.onChangeMonth = onChangeMonth
    }

    public var body: some View {
        PremiumGlassContainer(cornerRadius: Theme.Layout.buttonCornerRadius, padding: 8) {
            HStack {
                Button {
                    onChangeMonth(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.bold())
                        .foregroundStyle(Theme.Colors.primary)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Mês anterior")

                Spacer()

                Text(DateUtils.monthName(for: selectedDate))
                    .font(Theme.Typography.title3)
                    .primaryTextColor()
                    .contentTransition(.numericText())
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button {
                    onChangeMonth(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3.bold())
                        .foregroundStyle(Theme.Colors.primary)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Próximo mês")
            }
            .contentShape(.rect)
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 50 {
                        onChangeMonth(-1)
                    } else if value.translation.width < -50 {
                        onChangeMonth(1)
                    }
                }
        )
    }
}
