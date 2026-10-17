import SwiftUI
import SwiftData

struct AddAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @ScaledMetric(relativeTo: .largeTitle) private var monetaryInputSize: Double = 48

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
        _colorHex = State(initialValue: accountToEdit?.colorHex ?? "#FF6B00")
    }

    var body: some View {
        NavigationStack {
            BaseView {
                ScrollView {
                    VStack(spacing: 24) {
                        previewCard
                            .padding(.top, 16)

                        monetaryInput

                        GlassTextField(
                            title: "Nome da Conta",
                            placeholder: "Ex: Nubank, Itaú, Carteira...",
                            text: $name
                        )

                        colorPaletteSection

                        iconSelectorSection

                        if let account = accountToEdit {
                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                            } label: {
                                Text("Remover Conta")
                                    .font(Theme.Typography.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        Theme.Colors.error.opacity(0.15),
                                        in: .rect(cornerRadius: Theme.Layout.buttonCornerRadius)
                                    )
                                    .foregroundStyle(Theme.Colors.error)
                            }
                            .padding(.top, 16)
                            .confirmationDialog(
                                "Remover Conta",
                                isPresented: $showingDeleteConfirmation,
                                titleVisibility: .visible
                            ) {
                                Button("Remover Conta e Transações", role: .destructive) {
                                    modelContext.delete(account)
                                    dismiss()
                                }
                                Button("Cancelar", role: .cancel) {}
                            } message: {
                                Text("Deseja realmente remover a conta '\(account.name)'? Todas as transações vinculadas a ela também serão apagadas.")
                            }
                        }

                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal)
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
            }
            .navigationTitle(accountToEdit != nil ? "Editar Conta" : "Nova Conta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(Theme.Colors.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar", action: save)
                        .font(.headline)
                        .foregroundStyle(isValid ? Theme.Colors.primary : Theme.Colors.textSecondary)
                        .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - Components

    private var previewCard: some View {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: 48, height: 48)

                Image(systemName: iconSystemName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(trimmedName.isEmpty ? "Nome da Conta" : trimmedName)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(trimmedName.isEmpty ? Theme.Colors.textSecondary : Theme.Colors.textPrimary)
                    .lineLimit(1)

                Text(CurrencyFormatter.formatCurrency(initialBalanceCents))
                    .font(Theme.Typography.body)
                    .secondaryTextColor()
            }

            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(Color(hex: colorHex).opacity(isValid ? 1.0 : 0.0))
                .accessibilityHidden(true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cardCornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pré-visualização da conta: \(trimmedName.isEmpty ? "Sem nome" : trimmedName), saldo inicial \(CurrencyFormatter.formatCurrency(initialBalanceCents))")
    }

    private var monetaryInput: some View {
        VStack(spacing: 8) {
            Text("SALDO INICIAL")
                .font(Theme.Typography.caption1)
                .secondaryTextColor()

            HStack(alignment: .bottom, spacing: 4) {
                Text("R$")
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Colors.primary)
                    .padding(.bottom, 8)

                CurrencyTextField(valueInCents: $initialBalanceCents)
                    .font(.system(size: monetaryInputSize, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(minHeight: 80)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .glassEffectWithFallback(interactive: true)
        }
        .padding(.vertical, 8)
    }

    private var colorPaletteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("COR DE IDENTIFICAÇÃO")
                    .font(Theme.Typography.caption1)
                    .secondaryTextColor()
                    .padding(.leading, 4)

                Spacer()

                if let selected = AccountColor.presets.first(where: { $0.hex == colorHex }) {
                    Text(selected.name)
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(Color(hex: colorHex))
                }
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 16) {
                        ForEach(AccountColor.presets) { accountColor in
                            let isSelected = colorHex == accountColor.hex

                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    colorHex = accountColor.hex
                                }
                            } label: {
                                Circle()
                                    .fill(Color(hex: accountColor.hex))
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        Circle()
                                            .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                                            .padding(2)
                                    }
                                    .shadow(
                                        color: Color(hex: accountColor.hex).opacity(isSelected ? 0.6 : 0.0),
                                        radius: 12,
                                        x: 0,
                                        y: 6
                                    )
                                    .scaleEffect(isSelected ? 1.15 : 1.0)
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
            Text("ÍCONE")
                .font(Theme.Typography.caption1)
                .secondaryTextColor()
                .padding(.leading, 4)

            NavigationLink {
                IconSelectionView(selectedIcon: $iconSystemName, themeColorHex: colorHex)
            } label: {
                HStack {
                    Image(systemName: iconSystemName)
                        .font(.title2)
                        .foregroundStyle(Color(hex: colorHex))
                        .frame(width: 40)

                    Text("Mudar Ícone")
                        .font(Theme.Typography.body)
                        .primaryTextColor()

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .secondaryTextColor()
                }
                .padding()
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
