import SwiftUI
import SwiftData

struct AddCreditCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @ScaledMetric(relativeTo: .largeTitle) private var monetaryInputSize: Double = 44
    @Query private var accounts: [Account]

    @State private var name: String
    @State private var limitCents: Int
    @State private var closingDay: Int
    @State private var dueDay: Int
    @State private var iconSystemName: String
    @State private var colorHex: String
    @State private var paymentAccount: Account?
    @State private var showingDeleteConfirmation = false

    let cardToEdit: CreditCard?

    init(cardToEdit: CreditCard? = nil) {
        self.cardToEdit = cardToEdit
        _name = State(initialValue: cardToEdit?.name ?? "")
        _limitCents = State(initialValue: cardToEdit?.limitCents ?? 500_000)
        _closingDay = State(initialValue: cardToEdit?.closingDay ?? 5)
        _dueDay = State(initialValue: cardToEdit?.dueDay ?? 12)
        _iconSystemName = State(initialValue: cardToEdit?.iconSystemName ?? "creditcard.fill")
        _colorHex = State(initialValue: cardToEdit?.colorHex ?? "#1A5CFF")
        _paymentAccount = State(initialValue: cardToEdit?.paymentAccount)
    }

    var body: some View {
        NavigationStack {
            BaseView {
                ScrollView {
                    VStack(spacing: 24) {
                        previewCard
                            .padding(.top, 12)

                        limitInput

                        GlassTextField(
                            title: "Nome do Cartão",
                            placeholder: "Ex: Nubank, Itaú Personnalité, XP Visa...",
                            text: $name
                        )

                        paymentAccountSection

                        billingCycleCard

                        colorPaletteSection

                        iconSelectorSection

                        if let card = cardToEdit {
                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Excluir Cartão de Crédito", systemImage: "trash")
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
                                "Excluir Cartão de Crédito",
                                isPresented: $showingDeleteConfirmation,
                                titleVisibility: .visible
                            ) {
                                Button("Excluir Cartão e Faturas", role: .destructive) {
                                    TransactionService.deletePersistedInvoices(for: card, in: modelContext)
                                    modelContext.delete(card)
                                    dismiss()
                                }
                                Button("Cancelar", role: .cancel) {}
                            } message: {
                                Text("Deseja realmente excluir o cartão '\(card.name)'? Todos os lançamentos, faturas e parcelamentos vinculados a ele serão apagados.")
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
            .navigationTitle(cardToEdit != nil ? "Editar Cartão" : "Novo Cartão")
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
            .onAppear {
                if paymentAccount == nil {
                    paymentAccount = accounts.first
                }
            }
        }
    }

    // MARK: - Subviews

    private var previewCard: some View {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cardColor = Color(hex: colorHex)

        return VStack(alignment: .leading, spacing: 24) {
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

                Text("CRÉDITO")
                    .font(Theme.Typography.caption2)
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.16), in: .capsule)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(trimmedName.isEmpty ? "Nome do Cartão" : trimmedName)
                    .font(Theme.Typography.title3)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack {
                    Text("Limite: \(CurrencyFormatter.formatCurrency(limitCents))")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.white.opacity(0.9))

                    Spacer()

                    Text("Fecha dia \(closingDay) • Vence dia \(dueDay)")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [cardColor, cardColor.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: .rect(cornerRadius: Theme.Layout.cardCornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Layout.cardCornerRadius)
                .stroke(.white.opacity(0.28), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .shadow(color: cardColor.opacity(0.32), radius: 16, x: 0, y: 8)
    }

    private var limitInput: some View {
        VStack(spacing: 6) {
            Text("LIMITE TOTAL DO CARTÃO")
                .font(Theme.Typography.caption2)
                .secondaryTextColor()

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("R$")
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Color(hex: colorHex))

                CurrencyTextField(valueInCents: $limitCents)
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

    @ViewBuilder
    private var paymentAccountSection: some View {
        if !accounts.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("CONTA PARA PAGAMENTO DA FATURA")
                    .font(Theme.Typography.caption1)
                    .secondaryTextColor()
                    .padding(.leading, 4)

                Menu {
                    ForEach(accounts) { account in
                        Button {
                            paymentAccount = account
                        } label: {
                            Label(account.name, systemImage: account.iconSystemName)
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        if let account = paymentAccount {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: account.colorHex).gradient)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Image(systemName: account.iconSystemName)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.white)
                                }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(account.name)
                                    .font(Theme.Typography.headline)
                                    .primaryTextColor()

                                Text("Conta padrão para débito da fatura")
                                    .font(Theme.Typography.caption1)
                                    .secondaryTextColor()
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.Colors.surfaceElevated)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Image(systemName: "building.columns")
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                }

                            Text("Selecionar conta de pagamento")
                                .font(Theme.Typography.headline)
                                .secondaryTextColor()
                        }

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.footnote.bold())
                            .foregroundStyle(Theme.Colors.primary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cornerRadius))
                }
            }
        }
    }

    private var billingCycleCard: some View {
        PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 16) {
            VStack(spacing: 14) {
                HStack {
                    Label("Dia do Fechamento", systemImage: "calendar.badge.clock")
                        .font(Theme.Typography.subheadline)
                        .primaryTextColor()

                    Spacer()

                    Picker("Fechamento", selection: $closingDay) {
                        ForEach(1...31, id: \.self) { day in
                            Text("Dia \(day)").tag(day)
                        }
                    }
                    .tint(Theme.Colors.primary)
                }

                Divider()

                HStack {
                    Label("Dia do Vencimento", systemImage: "calendar.badge.exclamationmark")
                        .font(Theme.Typography.subheadline)
                        .primaryTextColor()

                    Spacer()

                    Picker("Vencimento", selection: $dueDay) {
                        ForEach(1...31, id: \.self) { day in
                            Text("Dia \(day)").tag(day)
                        }
                    }
                    .tint(Theme.Colors.primary)
                }
            }
        }
    }

    private var colorPaletteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("COR DO CARTÃO")
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
            Text("ÍCONE DO CARTÃO")
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
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && limitCents > 0
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, limitCents > 0 else { return }

        if let card = cardToEdit {
            card.name = trimmedName
            card.limitCents = limitCents
            card.closingDay = closingDay
            card.dueDay = dueDay
            card.iconSystemName = iconSystemName
            card.colorHex = colorHex
            card.paymentAccount = paymentAccount
            TransactionService.syncPersistedInvoices(for: card, in: modelContext)
        } else {
            let newCard = CreditCard(
                name: trimmedName,
                limitCents: limitCents,
                closingDay: closingDay,
                dueDay: dueDay,
                iconSystemName: iconSystemName,
                colorHex: colorHex,
                paymentAccount: paymentAccount ?? accounts.first
            )
            modelContext.insert(newCard)
        }
        dismiss()
    }
}
