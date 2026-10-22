import SwiftUI

struct IconSelectionView: View {
    @Binding var selectedIcon: String
    let themeColorHex: String
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 70), spacing: 16)]

    var body: some View {
        BaseView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(AccountColor.financeIcons, id: \.self) { icon in
                        let isSelected = selectedIcon == icon
                        let themeColor = Color(hex: themeColorHex)

                        Button {
                            withAnimation {
                                selectedIcon = icon
                                dismiss()
                            }
                        } label: {
                            Image(systemName: icon)
                                .font(.title)
                                .frame(width: 70, height: 70)
                                .background(
                                    Circle()
                                        .fill(isSelected ? themeColor.opacity(0.2) : Theme.Colors.surfaceSolid)
                                )
                                .overlay {
                                    Circle()
                                        .stroke(isSelected ? themeColor : Color.clear, lineWidth: 2)
                                }
                                .foregroundStyle(isSelected ? themeColor : Theme.Colors.textPrimary)
                        }
                        .accessibilityLabel(icon)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
                .padding(.vertical)
                .adaptiveContainer(maxWidth: Theme.Layout.maxFormWidth)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Escolher Ícone")
        .navigationBarTitleDisplayMode(.inline)
    }
}
