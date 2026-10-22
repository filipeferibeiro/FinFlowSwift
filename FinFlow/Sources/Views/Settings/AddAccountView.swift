import SwiftUI
import SwiftData

struct AddAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @ScaledMetric(relativeTo: .largeTitle) private var monetaryInputSize: Double = 44

    @State private var name: String
    @State private var initialBalanceCents: Int
    @State private var iconSystemName: String
    @State private var colorHex: String
    @State private var showingDeleteConfirmation = false

    let accountToEdit: Account?

    init(accountToEdit: Account? = nil) {
        self.accountToEdit = accountToEdit
        _name = State(initialValue: accountToEdit?.name ?? "")
        _initialBalanceCents = State(initialValue: accountToEdit?.initialBalanceCents ?? 0)
        _iconSystemName = State(initialValue: accountToEdit?.iconSystemName ?? "building.columns.fill")
        _colorHex = State(initialValue: accountToEdit?.colorHex ?? "#1A5CFF")
    }

    var body: some View {
        NavigationStack {
            BaseView {
                ScrollView {
                    VStack(spacing: 24) {
                        previewCard
                            .padding(.top, 12)

                        monetaryInput

                        GlassTextField(
                            title: "Nome da Instituição ou Carteira",
                            placeholder: "Ex: Itaú, Bradesco, Nubank, Reserva...",
                            text: $name
                        )

                        colorPaletteSection

                        iconSelectorSection

                        if let account = accountToEdit {
                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Excluir Conta", systemImage: "trash")
                                    .font(Theme.Typography.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        Theme.Colors.error.opacity(0.15),
                                        in: .rect(cornerRadius: Theme.Layout.buttonCornerRadius)
                                    )
                                    .foregroundStyle(Theme.Colors.error)
                            }
                            .padding(.top, 8)
                            .confirmationDialog(
                                "Excluir Conta",
                                isPresented: $showingDeleteConfirmation,
                                titleVisibility: .visible
                            ) {
                                Button("Excluir Conta e Lançamentos", role: .destructive) {
                                    modelContext.delete(account)
                                    dismiss()
                                }
                                Button("Cancelar", role: .cancel) {}
                            } message: {
                                Text("Deseja realmente excluir a conta '\(account.name)'? Todas as transações vinculadas a ela também serão removidas permanentemente.")
                            }
                        }

                        Spacer()
                            .frame(height: 40)
                    }
                    .adaptiveContainer(maxWidth: Theme.Layout.maxFormWidth)
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
            }
            .navigationTitle(accountToEdit != nil ? "Editar Conta" : "Nova Conta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm, action: save)
                        .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - Components

    private var previewCard: some View {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cardColor = Color(hex: colorHex)

        return VStack(alignment: .leading, spacing: 20) {
            HStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.20))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: iconSystemName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                    }

                Spacer()

                Image(systemName: isValid ? "checkmark.seal.fill" : "sparkles")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.85))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(trimmedName.isEmpty ? "Nome da Conta" : trimmedName)
                    .font(Theme.Typography.title3)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("Saldo inicial: \(CurrencyFormatter.formatCurrency(initialBalanceCents))")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [cardColor, cardColor.opacity(0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: .rect(cornerRadius: Theme.Layout.cardCornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Layout.cardCornerRadius)
                .stroke(.white.opacity(0.28), lineWidth: 1)
        }
        .shadow(color: cardColor.opacity(0.32), radius: 16, x: 0, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pré-visualização da conta: \(trimmedName.isEmpty ? "Sem nome" : trimmedName), saldo inicial \(CurrencyFormatter.formatCurrency(initialBalanceCents))")
    }

    private var monetaryInput: some View {
        VStack(spacing: 6) {
            Text("SALDO INICIAL DA CONTA")
                .font(Theme.Typography.caption2)
                .secondaryTextColor()

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("R$")
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Color(hex: colorHex))

                CurrencyTextField(valueInCents: $initialBalanceCents)
                    .font(.system(size: monetaryInputSize, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(minHeight: 72)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .glassEffectWithFallback(interactive: true)
        }
    }

    private var colorPaletteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("COR DO CARTÃO / CONTA")
                    .font(Theme.Typography.caption1)
                    .secondaryTextColor()
                    .padding(.leading, 4)

                Spacer()

                if let selected = AccountColor.presets.first(where: { $0.hex == colorHex }) {
                    Text(selected.name)
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Color(hex: colorHex))
                }
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 14) {
                        ForEach(AccountColor.presets) { accountColor in
                            let isSelected = colorHex == accountColor.hex

                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                    colorHex = accountColor.hex
                                }
                            } label: {
                                Circle()
                                    .fill(Color(hex: accountColor.hex).gradient)
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .overlay {
                                        Circle()
                                            .stroke(Color.white, lineWidth: isSelected ? 2.5 : 0)
                                            .padding(2)
                                    }
                                    .shadow(
                                        color: Color(hex: accountColor.hex).opacity(isSelected ? 0.55 : 0.0),
                                        radius: 10,
                                        x: 0,
                                        y: 5
                                    )
                                    .scaleEffect(isSelected ? 1.12 : 1.0)
                            }
                            .buttonStyle(.plain)
                            .id(accountColor.hex)
                            .accessibilityLabel(accountColor.name)
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
                .task {
                    withAnimation(.spring) {
                        proxy.scrollTo(colorHex, anchor: .center)
                    }
                }
                .onChange(of: colorHex) { _, newValue in
                    withAnimation(.spring) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
    }

    private var iconSelectorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ÍCONE DA CONTA")
                .font(Theme.Typography.caption1)
                .secondaryTextColor()
                .padding(.leading, 4)

            NavigationLink {
                IconSelectionView(selectedIcon: $iconSystemName, themeColorHex: colorHex)
            } label: {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: colorHex).opacity(0.15))
                        .frame(width: 42, height: 42)
                        .overlay {
                            Image(systemName: iconSystemName)
                                .font(.headline)
                                .foregroundStyle(Color(hex: colorHex))
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ícone Representativo")
                            .font(Theme.Typography.headline)
                            .primaryTextColor()

                        Text("Toque para escolher outro símbolo")
                            .font(Theme.Typography.caption1)
                            .secondaryTextColor()
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote.bold())
                        .foregroundStyle(Theme.Colors.primary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cornerRadius))
            }
        }
    }

    // MARK: - Helpers

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        if let account = accountToEdit {
            account.name = trimmedName
            account.initialBalanceCents = initialBalanceCents
            account.iconSystemName = iconSystemName
            account.colorHex = colorHex
        } else {
            let newAccount = Account(
                name: trimmedName,
                initialBalanceCents: initialBalanceCents,
                iconSystemName: iconSystemName,
                colorHex: colorHex
            )
            modelContext.insert(newAccount)
        }
        dismiss()
    }
}
