import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Namespace private var segmentNamespace
    
    @Query private var accounts: [Account]
    
    @State private var title: String = ""
    @State private var amountCents: Int = 0
    @State private var date: Date = Date()
    @State private var isPaid: Bool = true
    @State private var type: TransactionType = .expense
    
    @State private var selectedAccount: Account?
    @State private var targetAccount: Account?
    
    var body: some View {
        NavigationStack {
            BaseView {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // 1. Transaction Type Glass Selector
                        typeSelector
                            .padding(.top, 16)
                        
                        // 2. Huge Monetary Input
                        monetaryInput
                        
                        // 3. Title TextField
                        GlassTextField(title: "Título da Transação", placeholder: "Ex: Almoço, Netflix, Salário...", text: $title)
                        
                        // 4. Accounts Selection
                        VStack(spacing: 16) {
                            accountSelector(label: type == .transfer ? "Origem" : "Conta", selection: $selectedAccount, filter: nil)
                            
                            if type == .transfer {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(Theme.Colors.textSecondary)
                                
                                accountSelector(label: "Destino", selection: $targetAccount, filter: selectedAccount)
                            }
                        }
                        
                        // 5. Date and Paid Status
                        HStack(spacing: 16) {
                            FallbackGlassContainer {
                                DatePicker("Data", selection: $date, displayedComponents: .date)
                                    .labelsHidden()
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cornerRadius))
                            }
                            
                            FallbackGlassContainer {
                                Toggle(isOn: $isPaid) {
                                    Text(isPaid ? "Pago" : "Pendente")
                                        .font(Theme.Typography.subheadline)
                                        .primaryTextColor()
                                }
                                .tint(typeColor)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cornerRadius))
                            }
                        }
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Nova Transação")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(Theme.Colors.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { save() }
                        .font(.headline)
                        .foregroundStyle(isValid ? Theme.Colors.primary : Theme.Colors.textSecondary)
                        .disabled(!isValid)
                }
            }
            .onAppear {
                if selectedAccount == nil {
                    selectedAccount = accounts.first
                }
            }
            .onChange(of: date) { oldDate, newDate in
                let isFuture = Calendar.current.startOfDay(for: newDate) > Calendar.current.startOfDay(for: Date())
                withAnimation { isPaid = !isFuture }
            }
        }
    }
    
    // MARK: - Components
    
    private var typeColor: Color {
        switch type {
        case .income: return Theme.Colors.success
        case .expense: return Theme.Colors.error
        case .transfer: return Theme.Colors.primary
        }
    }
    
    private var typeSelector: some View {
        HStack(spacing: 0) {
            let options: [TransactionType] = accounts.count > 1 ? [.expense, .income, .transfer] : [.expense, .income]
            
            ForEach(options, id: \.self) { opt in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        type = opt
                    }
                }) {
                    Text(titleFor(opt))
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(type == opt ? .white : Theme.Colors.textSecondary)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                if type == opt {
                                    Capsule()
                                        .fill(typeColor)
                                        .shadow(color: typeColor.opacity(0.4), radius: 8, x: 0, y: 4)
                                        .matchedGeometryEffect(id: "GLASS_SEGMENT", in: segmentNamespace)
                                }
                            }
                        )
                }
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
                    .foregroundStyle(typeColor)
                    .padding(.bottom, 8)
                
                CurrencyTextField(valueInCents: $amountCents)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 80)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .glassEffectWithFallback(interactive: true)
        }
        .padding(.vertical, 16)
    }
    
    @ViewBuilder
    private func accountSelector(label: String, selection: Binding<Account?>, filter: Account?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(Theme.Typography.caption1)
                .secondaryTextColor()
                .padding(.leading, 4)
            
            Menu {
                ForEach(accounts.filter { $0.id != filter?.id }) { account in
                    Button {
                        selection.wrappedValue = account
                    } label: {
                        Label(account.name, systemImage: account.iconSystemName)
                    }
                }
            } label: {
                FallbackGlassContainer {
                    HStack {
                        if let account = selection.wrappedValue {
                            Image(systemName: account.iconSystemName)
                                .font(.system(size: 32))
                                .foregroundStyle(Color(hex: account.colorHex))
                            
                            VStack(alignment: .leading) {
                                Text(account.name)
                                    .font(Theme.Typography.headline)
                                    .primaryTextColor()
                                
                                Text(formatCurrency(account.currentBalanceCents))
                                    .font(Theme.Typography.caption1)
                                    .secondaryTextColor()
                            }
                        } else {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(Theme.Colors.textSecondary)
                            
                            Text("Selecione uma conta")
                                .font(Theme.Typography.headline)
                                .secondaryTextColor()
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 14))
                            .secondaryTextColor()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cornerRadius))
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func titleFor(_ type: TransactionType) -> String {
        switch type {
        case .income: return "Receita"
        case .expense: return "Despesa"
        case .transfer: return "Transferência"
        }
    }
    
    private func formatCurrency(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "BRL"
        formatter.locale = Locale(identifier: "pt_BR")
        
        let doubleValue = Double(cents) / 100.0
        return formatter.string(from: NSNumber(value: doubleValue)) ?? "R$ 0,00"
    }
    
    private var isValid: Bool {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty, amountCents > 0, selectedAccount != nil else { return false }
        if type == .transfer {
            return targetAccount != nil
        }
        return true
    }
    
    private func save() {
        let transaction = Transaction(
            title: title,
            amountCents: amountCents,
            date: date,
            isPaid: isPaid,
            type: type,
            account: selectedAccount,
            targetAccount: type == .transfer ? targetAccount : nil
        )
        modelContext.insert(transaction)
        dismiss()
    }
}
