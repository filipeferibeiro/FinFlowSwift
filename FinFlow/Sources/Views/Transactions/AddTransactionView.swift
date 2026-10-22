import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Namespace private var segmentNamespace

    @ScaledMetric(relativeTo: .largeTitle) private var monetaryInputSize: Double = 44

    @Query private var accounts: [Account]
    @Query private var creditCards: [CreditCard]

    @State private var title: String
    @State private var amountCents: Int
    @State private var date: Date
    @State private var isPaid: Bool
    @State private var type: TransactionType
    @State private var recurrenceMode: RecurrenceMode
    @State private var totalInstallments: Int
    @State private var divideAmountAcrossInstallments: Bool = true

    @State private var useCreditCard: Bool
    @State private var selectedAccount: Account?
    @State private var targetAccount: Account?
    @State private var selectedCreditCard: CreditCard?

    @State private var isAddingAccount = false
    @State private var showingEditRecurringDialog = false
    let transactionToEdit: Transaction?
    let isLockedToCreditCard: Bool

    init(
        transactionToEdit: Transaction? = nil,
        initialType: TransactionType = .expense,
        preselectedCreditCard: CreditCard? = nil
    ) {
        self.transactionToEdit = transactionToEdit
        self.isLockedToCreditCard = preselectedCreditCard != nil || transactionToEdit?.creditCard != nil

        _title = State(initialValue: transactionToEdit?.title ?? "")
        _amountCents = State(initialValue: transactionToEdit?.amountCents ?? 0)
        _date = State(initialValue: transactionToEdit?.date ?? .now)

        let editingCard = transactionToEdit?.creditCard ?? preselectedCreditCard
        _useCreditCard = State(initialValue: editingCard != nil)
        _selectedCreditCard = State(initialValue: editingCard)
        _isPaid = State(initialValue: transactionToEdit?.isPaid ?? (editingCard == nil))
        _type = State(initialValue: editingCard != nil ? .expense : (transactionToEdit?.type ?? initialType))

        let initialMode: RecurrenceMode = if let tx = transactionToEdit {
            if tx.isInstallment {
                .installment
            } else if tx.isFixed {
                .fixed
            } else {
                .single
            }
        } else {
            .single
        }
        _recurrenceMode = State(initialValue: initialMode)
        _totalInstallments = State(initialValue: transactionToEdit?.totalInstallments ?? 2)
        _selectedAccount = State(initialValue: transactionToEdit?.account)
        _targetAccount = State(initialValue: transactionToEdit?.targetAccount)
    }

    var body: some View {
        NavigationStack {
            BaseView {
                ScrollView {
                    VStack(spacing: 20) {
                        if !isLockedToCreditCard {
                            typeSelector
                                .padding(.top, 12)
                        }

                        monetaryInput
                            .padding(.top, isLockedToCreditCard ? 12 : 0)

                        GlassTextField(
                            title: "Descrição",
                            placeholder: placeholderText,
                            text: $title
                        )

                        // Payment source: Account vs Credit Card
                        paymentSourceSection

                        // Recurrence / Installment Section (Single, Parcelado, Fixo)
                        recurrenceSection

                        // Date & Paid status card
                        dateAndStatusCard

                        Spacer()
                            .frame(height: 40)
                    }
                    .adaptiveContainer(maxWidth: Theme.Layout.maxFormWidth)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(navigationBarTitle)
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
                if selectedAccount == nil {
                    selectedAccount = accounts.first
                }
                if selectedCreditCard == nil {
                    selectedCreditCard = creditCards.first
                }
                ensureValidTransferAccounts()
            }
            .onChange(of: accounts) { _, _ in
                if selectedAccount == nil {
                    selectedAccount = accounts.first
                }
                ensureValidTransferAccounts()
            }
            .onChange(of: type) { _, newType in
                if newType != .expense {
                    useCreditCard = false
                }
                if newType == .transfer && title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    title = "Transferência entre contas"
                }
                ensureValidTransferAccounts()
            }
            .onChange(of: selectedAccount) { _, _ in
                ensureValidTransferAccounts()
            }
            .onChange(of: useCreditCard) { _, isCard in
                if isCard {
                    type = .expense
                    isPaid = false
                    if selectedCreditCard == nil {
                        selectedCreditCard = creditCards.first
                    }
                }
            }
            .onChange(of: date) { oldDate, newDate in
                guard !useCreditCard, !Calendar.current.isDate(oldDate, inSameDayAs: newDate) else { return }
                let isFuture = Calendar.current.startOfDay(for: newDate) > Calendar.current.startOfDay(for: .now)
                withAnimation {
                    isPaid = !isFuture
                }
            }
            .sheet(isPresented: $isAddingAccount) {
                AddAccountView()
            }
            .confirmationDialog(
                transactionToEdit?.isInstallment == true ? "Editar Parcelamento" : "Editar Lançamento Recorrente",
                isPresented: $showingEditRecurringDialog,
                titleVisibility: .visible
            ) {
                Button(transactionToEdit?.isInstallment == true ? "Alterar apenas esta parcela" : "Alterar apenas este mês") {
                    if let tx = transactionToEdit {
                        TransactionService.saveRecurringOverride(draft: currentDraft, for: tx, in: modelContext)
                    }
                    dismiss()
                }

                Button(transactionToEdit?.isInstallment == true ? "Alterar esta e as próximas parcelas" : "Alterar este e os próximos") {
                    if let tx = transactionToEdit {
                        TransactionService.saveRecurringFuture(draft: currentDraft, for: tx, in: modelContext)
                    }
                    dismiss()
                }

                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Deseja aplicar as alterações apenas a este item ou também aos seguintes?")
            }
        }
    }

    private var placeholderText: String {
        if useCreditCard {
            return "Ex: iPhone, Restaurante, Uber..."
        }
        return switch type {
        case .expense: "Ex: Almoço, Aluguel, Energia..."
        case .income: "Ex: Salário, Dividendos, Freelance..."
        case .transfer: "Ex: Reserva de Emergência, Investimento..."
        }
    }

    private var navigationBarTitle: String {
        if transactionToEdit != nil {
            return useCreditCard ? "Editar Compra" : "Editar Lançamento"
        }
        if useCreditCard {
            return "Nova Compra no Cartão"
        }
        return switch type {
        case .expense: "Nova Despesa"
        case .income: "Nova Receita"
        case .transfer: "Nova Transferência"
        }
    }

    // MARK: - Components

    private var typeSelector: some View {
        let options: [TransactionType] = [.expense, .income, .transfer]

        return HStack(spacing: 0) {
            ForEach(options) { opt in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        type = opt
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: opt.iconSystemName)
                            .font(.caption.bold())
                        Text(opt.title)
                            .font(Theme.Typography.subheadline)
                    }
                    .foregroundStyle(type == opt ? .white : Theme.Colors.textSecondary)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background {
                        if type == opt {
                            Capsule()
                                .fill(type.color.gradient)
                                .shadow(color: type.color.opacity(0.35), radius: 8, x: 0, y: 4)
                                .matchedGeometryEffect(id: "GLASS_SEGMENT", in: segmentNamespace)
                        }
                    }
                }
                .accessibilityAddTraits(type == opt ? .isSelected : [])
            }
        }
        .padding(4)
        .glassEffectWithFallback(in: .capsule)
    }

    private var monetaryInput: some View {
        let activeColor = useCreditCard ? Theme.Colors.primary : type.color

        return VStack(spacing: 6) {
            Text(recurrenceMode == .installment && transactionToEdit == nil
                 ? (divideAmountAcrossInstallments ? "VALOR TOTAL DA COMPRA" : "VALOR DE CADA PARCELA")
                 : "VALOR DO LANÇAMENTO")
                .font(Theme.Typography.caption2)
                .secondaryTextColor()

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("R$")
                    .font(Theme.Typography.title2)
                    .foregroundStyle(activeColor)

                CurrencyTextField(valueInCents: $amountCents)
                    .font(.system(size: monetaryInputSize, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(minHeight: 72)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .glassEffectWithFallback(interactive: true)
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                    .stroke(activeColor.opacity(0.35), lineWidth: 1.5)
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private var paymentSourceSection: some View {
        VStack(spacing: 14) {
            if type == .expense && !creditCards.isEmpty && !isLockedToCreditCard && transactionToEdit == nil {
                HStack(spacing: 10) {
                    paymentMethodPill(
                        title: "Conta Bancária",
                        icon: "building.columns.fill",
                        isSelected: !useCreditCard
                    ) {
                        withAnimation(.snappy) {
                            useCreditCard = false
                        }
                    }

                    paymentMethodPill(
                        title: "Cartão de Crédito",
                        icon: "creditcard.fill",
                        isSelected: useCreditCard
                    ) {
                        withAnimation(.snappy) {
                            useCreditCard = true
                        }
                    }
                }
            }

            if useCreditCard {
                creditCardSelector
            } else {
                accountSelector(
                    label: type == .transfer ? "Conta de Origem" : "Conta",
                    selection: $selectedAccount,
                    excluding: nil
                )

                if type == .transfer {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.Colors.primary)
                        .accessibilityHidden(true)

                    if accounts.count < 2 {
                        PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 16) {
                            VStack(spacing: 10) {
                                Text("Você precisa de pelo menos 2 contas para realizar uma transferência.")
                                    .font(Theme.Typography.caption1)
                                    .secondaryTextColor()
                                    .multilineTextAlignment(.center)

                                Button {
                                    isAddingAccount = true
                                } label: {
                                    Label("Adicionar Nova Conta", systemImage: "plus")
                                        .font(Theme.Typography.subheadline)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Theme.Colors.primary.gradient, in: .capsule)
                                }
                                .buttonStyle(.plain)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        accountSelector(
                            label: "Conta de Destino",
                            selection: $targetAccount,
                            excluding: selectedAccount
                        )
                    }
                }
            }
        }
    }

    private func paymentMethodPill(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.bold())
                Text(title)
                    .font(Theme.Typography.subheadline)
            }
            .foregroundStyle(isSelected ? .white : Theme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected ? AnyShapeStyle(Theme.Colors.primary.gradient) : AnyShapeStyle(.ultraThinMaterial),
                in: .rect(cornerRadius: 14)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.clear : Theme.Colors.cardBorder, lineWidth: 1)
                    .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var creditCardSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CARTÃO DE CRÉDITO")
                .font(Theme.Typography.caption1)
                .secondaryTextColor()
                .padding(.leading, 4)

            Menu {
                ForEach(creditCards) { card in
                    Button {
                        selectedCreditCard = card
                    } label: {
                        Label(card.name, systemImage: card.iconSystemName)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    if let card = selectedCreditCard {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: card.colorHex).gradient)
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: card.iconSystemName)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(card.name)
                                .font(Theme.Typography.headline)
                                .primaryTextColor()

                            Text("Fecha dia \(card.closingDay) • Vence dia \(card.dueDay)")
                                .font(Theme.Typography.caption1)
                                .secondaryTextColor()
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.Colors.surfaceElevated)
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: "creditcard")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }

                        Text("Selecione um cartão")
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

    @ViewBuilder
    private var recurrenceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FREQUÊNCIA E PARCELAMENTO")
                .font(Theme.Typography.caption1)
                .secondaryTextColor()
                .padding(.leading, 4)

            if let tx = transactionToEdit, tx.isInstallment {
                PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 14) {
                    HStack {
                        Label("Parcela \(tx.installmentBadgeText ?? "")", systemImage: "square.stack.3d.up.fill")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.primary)
                        Spacer()
                        Text("Lançamento parcelado")
                            .font(Theme.Typography.caption1)
                            .secondaryTextColor()
                    }
                }
            } else {
                let modes: [RecurrenceMode] = transactionToEdit == nil
                    ? RecurrenceMode.allCases
                    : [.single, .fixed]

                HStack(spacing: 8) {
                    ForEach(modes) { mode in
                        let isSelected = recurrenceMode == mode

                        Button {
                            withAnimation(.snappy) {
                                recurrenceMode = mode
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: mode.iconSystemName)
                                    .font(.caption.bold())
                                Text(mode.title)
                                    .font(Theme.Typography.subheadline)
                            }
                            .foregroundStyle(isSelected ? .white : Theme.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                isSelected
                                    ? AnyShapeStyle(Theme.Colors.primary.gradient)
                                    : AnyShapeStyle(.ultraThinMaterial),
                                in: .rect(cornerRadius: 14)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected ? Color.clear : Theme.Colors.cardBorder, lineWidth: 1)
                                    .allowsHitTesting(false)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }

                if recurrenceMode == .installment && transactionToEdit == nil {
                    installmentConfigCard
                } else if recurrenceMode == .fixed {
                    PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 14) {
                        HStack(spacing: 10) {
                            Image(systemName: "repeat.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Theme.Colors.primary)
                            Text("Este lançamento será repetido automaticamente todos os meses.")
                                .font(Theme.Typography.caption1)
                                .secondaryTextColor()
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var installmentConfigCard: some View {
        let count = max(2, totalInstallments)
        let perInstallmentCents = divideAmountAcrossInstallments ? (amountCents / count) : amountCents
        let totalPurchaseCents = divideAmountAcrossInstallments ? amountCents : (amountCents * count)

        return PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 16) {
            VStack(spacing: 14) {
                HStack {
                    Label("Número de Parcelas", systemImage: "number.circle.fill")
                        .font(Theme.Typography.subheadline)
                        .primaryTextColor()

                    Spacer()

                    Picker("Parcelas", selection: $totalInstallments) {
                        ForEach(2...48, id: \.self) { number in
                            Text("\(number)x").tag(number)
                        }
                    }
                    .tint(Theme.Colors.primary)
                }

                Divider()

                Toggle(isOn: $divideAmountAcrossInstallments) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(divideAmountAcrossInstallments ? "Dividir valor entre as parcelas" : "Repetir valor em cada parcela")
                            .font(Theme.Typography.subheadline)
                            .primaryTextColor()
                        Text(divideAmountAcrossInstallments ? "O valor digitado acima é o total da compra" : "O valor digitado acima é o de cada parcela")
                            .font(Theme.Typography.caption2)
                            .secondaryTextColor()
                    }
                }
                .tint(Theme.Colors.primary)

                if amountCents > 0 {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.caption.bold())
                            .foregroundStyle(Theme.Colors.primary)

                        Text("\(count)x de \(CurrencyFormatter.formatCurrency(perInstallmentCents))")
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundStyle(Theme.Colors.primary)

                        Spacer()

                        Text("Total: \(CurrencyFormatter.formatCurrency(totalPurchaseCents))")
                            .font(Theme.Typography.caption1)
                            .secondaryTextColor()
                    }
                    .padding(10)
                    .background(Theme.Colors.primary.opacity(0.10), in: .rect(cornerRadius: 10))
                }
            }
        }
    }

    private var dateAndStatusCard: some View {
        PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 16) {
            VStack(spacing: 16) {
                HStack {
                    Label(
                        recurrenceMode == .installment && transactionToEdit == nil ? "Data da 1ª Parcela" : "Data",
                        systemImage: "calendar"
                    )
                    .font(Theme.Typography.subheadline)
                    .primaryTextColor()

                    Spacer()

                    DatePicker("Data", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                        .tint(Theme.Colors.primary)
                }

                if !useCreditCard {
                    Divider()

                    Toggle(isOn: $isPaid) {
                        HStack(spacing: 10) {
                            Image(systemName: isPaid ? "checkmark.circle.fill" : "clock.fill")
                                .foregroundStyle(isPaid ? Theme.Colors.success : Theme.Colors.warning)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isPaid ? "Lançamento Efetivado" : "Lançamento Pendente")
                                    .font(Theme.Typography.subheadline)
                                    .primaryTextColor()
                                Text(isPaid ? "Já contabilizado no saldo atual" : "Contabilizado apenas no saldo previsto")
                                    .font(Theme.Typography.caption2)
                                    .secondaryTextColor()
                            }
                        }
                    }
                    .tint(Theme.Colors.success)
                }
            }
        }
    }

    @ViewBuilder
    private func accountSelector(
        label: String,
        selection: Binding<Account?>,
        excluding excludedAccount: Account?
    ) -> some View {
        let availableAccounts = accounts.filter { $0.id != excludedAccount?.id }

        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(Theme.Typography.caption1)
                .secondaryTextColor()
                .padding(.leading, 4)

            Menu {
                ForEach(availableAccounts) { account in
                    Button {
                        selection.wrappedValue = account
                    } label: {
                        Label(account.name, systemImage: account.iconSystemName)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    if let account = selection.wrappedValue {
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

                            Text("Saldo: \(CurrencyFormatter.formatCurrency(account.currentBalanceCents))")
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

                        Text("Selecione uma conta")
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

    // MARK: - Helpers

    private var currentDraft: TransactionDraft {
        TransactionDraft(
            title: title,
            amountCents: amountCents,
            date: date,
            isPaid: useCreditCard ? (transactionToEdit?.isPaid ?? false) : isPaid,
            type: useCreditCard ? .expense : type,
            recurrenceMode: recurrenceMode,
            totalInstallments: totalInstallments,
            divideAmountAcrossInstallments: divideAmountAcrossInstallments,
            account: useCreditCard ? nil : selectedAccount,
            targetAccount: useCreditCard ? nil : targetAccount,
            creditCard: useCreditCard ? selectedCreditCard : nil
        )
    }

    private var isValid: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              amountCents > 0 else {
            return false
        }
        if useCreditCard {
            return selectedCreditCard != nil
        }
        guard let origin = selectedAccount else { return false }
        if type == .transfer {
            guard let destination = targetAccount else { return false }
            return destination.id != origin.id
        }
        return true
    }

    private func ensureValidTransferAccounts() {
        guard type == .transfer, !useCreditCard else { return }
        if targetAccount == nil || targetAccount?.id == selectedAccount?.id {
            targetAccount = accounts.first { $0.id != selectedAccount?.id }
        }
    }

    private func save() {
        if let tx = transactionToEdit, tx.isRecurringOrInstallment {
            showingEditRecurringDialog = true
        } else {
            TransactionService.saveNewOrNonRecurring(
                draft: currentDraft,
                editing: transactionToEdit,
                in: modelContext
            )
            dismiss()
        }
    }
}
