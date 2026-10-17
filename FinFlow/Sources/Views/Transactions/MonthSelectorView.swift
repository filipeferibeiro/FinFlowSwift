import SwiftUI

public struct MonthSelectorView: View {
    let selectedDate: Date
    @Binding var selectedFilter: TransactionFilter
    let onChangeMonth: (Int) -> Void

    public init(
        selectedDate: Date,
        selectedFilter: Binding<TransactionFilter>,
        onChangeMonth: @escaping (Int) -> Void
    ) {
        self.selectedDate = selectedDate
        self._selectedFilter = selectedFilter
        self.onChangeMonth = onChangeMonth
    }

    public var body: some View {
        VStack(spacing: 10) {
            PremiumGlassContainer(cornerRadius: Theme.Layout.buttonCornerRadius, padding: 6) {
                HStack {
                    Button {
                        onChangeMonth(-1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.subheadline.bold())
                            .foregroundStyle(Theme.Colors.primary)
                            .frame(width: 44, height: 44)
                            .background(Theme.Colors.primary.opacity(0.10), in: .circle)
                    }
                    .accessibilityLabel("Mês anterior")

                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.subheadline.bold())
                            .foregroundStyle(Theme.Colors.primary)

                        Text(DateUtils.monthName(for: selectedDate))
                            .font(Theme.Typography.title3)
                            .primaryTextColor()
                            .contentTransition(.numericText())
                    }
                    .accessibilityAddTraits(.isHeader)

                    Spacer()

                    Button {
                        onChangeMonth(1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.subheadline.bold())
                            .foregroundStyle(Theme.Colors.primary)
                            .frame(width: 44, height: 44)
                            .background(Theme.Colors.primary.opacity(0.10), in: .circle)
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

            // Quick Filter Chips
            HStack(spacing: 8) {
                ForEach(TransactionFilter.allCases) { filter in
                    let isSelected = selectedFilter == filter

                    Button {
                        withAnimation(.snappy) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.title)
                            .font(Theme.Typography.caption1)
                            .foregroundStyle(isSelected ? .white : Theme.Colors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                isSelected
                                    ? AnyShapeStyle(Theme.Colors.primary.gradient)
                                    : AnyShapeStyle(.ultraThinMaterial),
                                in: .capsule
                            )
                            .overlay {
                                Capsule()
                                    .stroke(isSelected ? Color.clear : Theme.Colors.cardBorder, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }
}
