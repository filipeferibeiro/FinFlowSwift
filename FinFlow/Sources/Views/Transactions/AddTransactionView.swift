import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Namespace private var segmentNamespace

    @ScaledMetric(relativeTo: .largeTitle) private var monetaryInputSize: Double = 48

    @Query private var accounts: [Account]

    @State private var title: String
    @State private var amountCents: Int
    @State private var date: Date
    @State private var isPaid: Bool
    @State private var type: TransactionType
    @State private var isFixed: Bool

    @State private var selectedAccount: Account?
    @State private var targetAccount: Account?

    @State private var showingEditRecurringDialog = false
    let transactionToEdit: Transaction?

    init(transactionToEdit: Transaction? = nil) {
        self.transactionToEdit = transactionToEdit
        _title = State(initialValue: transactionToEdit?.title ?? "")
        _amountCents = State(initialValue: transactionToEdit?.amountCents ?? 0)
        _date = State(initialValue: transactionToEdit?.date ?? .now)
        _isPaid = State(initialValue: transactionToEdit?.isPaid ?? true)
        _type = State(initialValue: transactionToEdit?.type ?? .expense)
        _isFixed = State(initialValue: transactionToEdit?.isFixed ?? false)
        _selectedAccount = State(initialValue: transactionToEdit?.account)
        _targetAccount = State(initialValue: transactionToEdit?.targetAccount)
    }

    var body: some View {
        NavigationStack {
            BaseView {
                ScrollView {
                    VStack(spacing: 24) {
                        typeSelector
                            .padding(.top, 16)

                        monetaryInput

                        GlassTextField(
                            title: "Título da Transação",
                            placeholder: "Ex: Almoço, Netflix, Salário...",
                            text: $title
                        )

                        VStack(spacing: 16) {
                            accountSelector(
                                label: type == .transfer ? "Conta de Origem" : "Conta",
                                selection: $selectedAccount,
                                excluding: nil
                            )

                            if type == .transfer {
                                Image(systemName: "arrow.down")
                                    .font(.title2.bold())
                                    .foregroundStyle(Theme.Colors.textSecondary)
                                    .accessibilityHidden(true)

                                accountSelector(
                                    label: "Conta de Destino",
                                    selection: $targetAccount,
                                    excluding: selectedAccount
                                )
                            }
                        }

                        FallbackGlassContainer(spacing: 16) {
                            HStack(spacing: 16) {
                                DatePicker("Data", selection: $date, displayedComponents: .date)
                                    .labelsHidden()
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cornerRadius))

                                Toggle(isOn: $isPaid) {
                                    Text(isPaid ? "Pago" : "Pendente")
                                        .font(Theme.Typography.subheadline)
                                        .primaryTextColor()
                                }
                                .tint(type.color)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cornerRadius))
                            }
                        }

                        Toggle(isOn: $isFixed) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Transação Fixa")
                                    .font(Theme.Typography.subheadline)
                                    .primaryTextColor()
                                Text("Repetir todos os meses")
                                    .font(Theme.Typography.caption2)
                                    .secondaryTextColor()
                            }
                        }
                        .tint(Theme.Colors.primary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cornerRadius))

                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(transactionToEdit != nil ? "Editar Transação" : "Nova Transação")
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
            .onAppear {
                if selectedAccount == nil {
                    selectedAccount = accounts.first
                }
                ensureValidTransferAccounts()
            }
            .onChange(of: type) { _, _ in
                ensureValidTransferAccounts()
            }
            .onChange(of: selectedAccount) { _, _ in
                ensureValidTransferAccounts()
            }
            .onChange(of: date) { oldDate, newDate in
                guard !Calendar.current.isDate(oldDate, inSameDayAs: newDate) else { return }
                let isFuture = Calendar.current.startOfDay(for: newDate) > Calendar.current.startOfDay(for: .now)
                withAnimation {
                    isPaid = !isFuture
                }
            }
            .confirmationDialog(
                "Editar Transação Fixa",
                isPresented: $showingEditRecurringDialog,
                titleVisibility: .visible
            ) {
                Button("Editar apenas esta") {
                    if let tx = transactionToEdit {
                        TransactionService.saveRecurringOverride(draft: currentDraft, for: tx, in: modelContext)
                    }
                    dismiss()
                }

                Button("Editar esta e as próximas") {
                    if let tx = transactionToEdit {
                        TransactionService.saveRecurringFuture(draft: currentDraft, for: tx, in: modelContext)
                    }
                    dismiss()
                }

                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Deseja aplicar as alterações apenas a esta transação ou a todas as seguintes?")
            }
        }
    }

    // MARK: - Components

    private var typeSelector: some View {
        let options: [TransactionType] = accounts.count > 1 ? [.expense, .income, .transfer] : [.expense, .income]

        return HStack(spacing: 0) {
            ForEach(options) { opt in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        type = opt
                    }
                } label: {
                    Text(opt.title)
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(type == opt ? .white : Theme.Colors.textSecondary)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background {
                            if type == opt {
                                Capsule()
                                    .fill(type.color)
                                    .shadow(color: type.color.opacity(0.4), radius: 8, x: 0, y: 4)
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
        VStack(spacing: 8) {
            Text("VALOR")
                .font(Theme.Typography.caption1)
                .secondaryTextColor()

            HStack(alignment: .bottom, spacing: 4) {
                Text("R$")
                    .font(Theme.Typography.title2)
                    .foregroundStyle(type.color)
                    .padding(.bottom, 8)

                CurrencyTextField(valueInCents: $amountCents)
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
                        Image(systemName: account.iconSystemName)
                            .font(.title2)
                            .foregroundStyle(Color(hex: account.colorHex))
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.name)
                                .font(Theme.Typography.headline)
                                .primaryTextColor()

                            Text(CurrencyFormatter.formatCurrency(account.currentBalanceCents))
                                .font(Theme.Typography.caption1)
                                .secondaryTextColor()
                        }
                    } else {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .frame(width: 36)

                        Text("Selecione uma conta")
                            .font(Theme.Typography.headline)
                            .secondaryTextColor()
                    }

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
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

    private var currentDraft: TransactionDraft {
        TransactionDraft(
            title: title,
            amountCents: amountCents,
            date: date,
            isPaid: isPaid,
            type: type,
            isFixed: isFixed,
            account: selectedAccount,
            targetAccount: targetAccount
        )
    }

    private var isValid: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              amountCents > 0,
              let origin = selectedAccount else {
            return false
        }
        if type == .transfer {
            guard let destination = targetAccount else { return false }
            return destination.id != origin.id
        }
        return true
    }

    private func ensureValidTransferAccounts() {
        guard type == .transfer else { return }
        if targetAccount == nil || targetAccount?.id == selectedAccount?.id {
            targetAccount = accounts.first { $0.id != selectedAccount?.id }
        }
    }

    private func save() {
        if let tx = transactionToEdit, tx.isFixed {
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
