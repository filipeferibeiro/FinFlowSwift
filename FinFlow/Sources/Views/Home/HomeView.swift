import SwiftUI
import SwiftData

public struct HomeView: View {
    @AppStorage("userName") private var userName: String = "Usuário"
    @Query private var accounts: [Account]
    
    @State private var isBalanceVisible: Bool = true
    @State private var isAddingTransaction: Bool = false
    @State private var accountToEdit: Account?
    
    private var totalBalanceCents: Int {
        accounts.reduce(0) { $0 + $1.currentBalanceCents }
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "Bom dia"
        case 12..<18: return "Boa tarde"
        case 18..<24, 0..<6: return "Boa noite"
        default: return "Olá"
        }
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            BaseView {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: Theme.Layout.standardPadding) {
                        
                        // Header / Total Balance
                        balanceHeader
                        
                        // Accounts Section
                        accountsSection
                        
                        // Credit Cards Section
                        creditCardsSection
                        
                        // Spacer for bottom padding to avoid tab bar and FAB collision
                        Spacer().frame(height: 100)
                    }
                    .padding()
                }
                .overlay(alignment: .bottomTrailing) {
                    floatingActionButton
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline) // A bit cleaner for minimalist feel
            .scrollEdgeEffectStyle(.soft, for: .top)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        withAnimation(.easeInOut) {
                            isBalanceVisible.toggle()
                        }
                    }) {
                        Image(systemName: isBalanceVisible ? "eye.fill" : "eye.slash.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.Colors.primary)
                            .accessibilityLabel(isBalanceVisible ? "Ocultar Saldo" : "Mostrar Saldo")
                    }
                }
            }
            .sheet(isPresented: $isAddingTransaction) {
                AddTransactionView()
            }
            .sheet(item: $accountToEdit) { account in
                AddAccountView(accountToEdit: account)
            }
        }
    }
    
    // MARK: - Components
    
    private var balanceHeader: some View {
        VStack(spacing: 8) {
            Text("\(greeting), \(userName)")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.textSecondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("R$")
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.Colors.textTertiary)
                
                Text(isBalanceVisible ? formatAmount(totalBalanceCents) : "•••••")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .contentTransition(.numericText())
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var floatingActionButton: some View {
        Button(action: {
            isAddingTransaction = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .padding(16)
                .background(Theme.Colors.primary.opacity(0.4), in: .circle)
                .glassEffectWithFallback(in: .circle)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
    
    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Minhas Contas")
                .font(Theme.Typography.headline)
                .primaryTextColor()
            
            if accounts.isEmpty {
                FallbackGlassContainer {
                    Text("Nenhuma conta cadastrada.")
                        .font(Theme.Typography.body)
                        .secondaryTextColor()
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(accounts) { account in
                    FallbackGlassContainer {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: account.colorHex))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: account.iconSystemName)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(account.name)
                                    .font(Theme.Typography.body)
                                    .primaryTextColor()
                            }
                            
                            Spacer()
                            
                            Text(isBalanceVisible ? formatCurrency(account.currentBalanceCents) : "R$ •••••")
                                .font(Theme.Typography.headline)
                                .primaryTextColor()
                                .contentTransition(.numericText())
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cornerRadius))
                    }
                    .buttonStyle(.plain)
                    .onTapGesture {
                        accountToEdit = account
                    }
                }
            }
        }
    }
    
    private var creditCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cartões de Crédito")
                .font(Theme.Typography.headline)
                .primaryTextColor()
            
            FallbackGlassContainer {
                HStack {
                    Image(systemName: "creditcard.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.Colors.primary)
                    
                    VStack(alignment: .leading) {
                        Text("Cartão Nubank")
                            .font(Theme.Typography.body)
                            .primaryTextColor()
                        Text("Fatura atual")
                            .font(Theme.Typography.caption1)
                            .secondaryTextColor()
                    }
                    
                    Spacer()
                    
                    Text(isBalanceVisible ? formatCurrency(120500) : "R$ •••••")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.error) // Red for expenses
                        .contentTransition(.numericText())
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cornerRadius))
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatCurrency(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "BRL"
        formatter.locale = Locale(identifier: "pt_BR")
        
        let doubleValue = Double(cents) / 100.0
        return formatter.string(from: NSNumber(value: doubleValue)) ?? "R$ 0,00"
    }
    
    private func formatAmount(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: "pt_BR")
        
        let doubleValue = Double(cents) / 100.0
        return formatter.string(from: NSNumber(value: doubleValue)) ?? "0,00"
    }
}


