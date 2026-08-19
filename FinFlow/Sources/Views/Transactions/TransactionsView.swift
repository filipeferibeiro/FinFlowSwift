import SwiftUI
import SwiftData

public struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query private var accounts: [Account]
    
    @State private var selectedDate: Date = Date()
    @State private var transactionToDelete: Transaction?
    @State private var showingDeleteAlert = false
    @State private var isAddingTransaction = false
    @State private var disintegratingTxIDs: Set<PersistentIdentifier> = []
    
    public init() {}
    
    private var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        return allTransactions.filter { 
            calendar.isDate($0.date, equalTo: selectedDate, toGranularity: .month)
        }
    }
    
    private var groupedTransactions: [(Date, [Transaction])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredTransactions) { tx in
            calendar.startOfDay(for: tx.date)
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    public var body: some View {
        NavigationStack {
            BaseView {
                ZStack(alignment: .top) {
                    List {
                        Spacer()
                            .frame(height: 90)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            
                        // Overview Card (now scrolls with the list)
                        monthOverview
                            .padding(.bottom, 8)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        
                        // Transactions List
                        if filteredTransactions.isEmpty {
                            emptyState
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .padding(.top, 40)
                        } else {
                            ForEach(groupedTransactions, id: \.0) { date, transactions in
                                Section {
                                    ForEach(transactions) { tx in
                                        transactionRow(tx)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button {
                                                    transactionToDelete = tx
                                                    showingDeleteAlert = true
                                                } label: {
                                                    Label("Excluir", systemImage: "trash")
                                                }
                                                .tint(Theme.Colors.error)
                                            }
                                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                                Button {
                                                    withAnimation {
                                                        tx.isPaid.toggle()
                                                    }
                                                } label: {
                                                    Label(tx.isPaid ? "Marcar Pendente" : "Marcar Pago", systemImage: tx.isPaid ? "xmark.circle" : "checkmark.circle")
                                                }
                                                .tint(tx.isPaid ? Theme.Colors.warning : Theme.Colors.success)
                                            }
                                    }
                                } header: {
                                    Text(formattedDay(date))
                                        .font(Theme.Typography.headline)
                                        .primaryTextColor()
                                        .textCase(nil)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                }
                                .listRowInsets(EdgeInsets()) // Ensure header has full width internally
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                    .scrollIndicators(.hidden)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.1), value: filteredTransactions)
                    
                    // Month Selector floating on top
                    monthSelector
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }
                .overlay(alignment: .bottomTrailing) {
                    floatingActionButton
                }
            }
            .navigationTitle("Extrato")
            .navigationBarTitleDisplayMode(.inline)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .alert("Excluir Transação", isPresented: $showingDeleteAlert, presenting: transactionToDelete) { tx in
                Button("Cancelar", role: .cancel) {
                    transactionToDelete = nil
                }
                Button("Excluir", role: .destructive) {
                    let txID = tx.persistentModelID
                    withAnimation(.easeOut(duration: 0.8)) {
                        _ = disintegratingTxIDs.insert(txID)
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        modelContext.delete(tx)
                        
                        // Clean up the ID later so it doesn't flash back on screen before the List removes it
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            disintegratingTxIDs.remove(txID)
                        }
                    }
                    transactionToDelete = nil
                }
            } message: { tx in
                Text("Deseja realmente excluir a transação '\(tx.title)' no valor de \(formatCurrency(tx.amountCents)) da conta \(tx.account?.name ?? "Sem Conta")?\n\nEsta ação não pode ser desfeita.")
            }
            .sheet(isPresented: $isAddingTransaction) {
                AddTransactionView()
            }
        }
    }
    
    // MARK: - Components
    
    private var monthSelector: some View {
        PremiumGlassContainer(cornerRadius: Theme.Layout.buttonCornerRadius, padding: 8) {
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.Colors.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                
                Spacer()
                
                Text(monthName(for: selectedDate))
                    .font(Theme.Typography.title3)
                    .primaryTextColor()
                    .contentTransition(.numericText())
                
                Spacer()
                
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.Colors.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }
            .contentShape(Rectangle())
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 50 {
                        changeMonth(by: -1)
                    } else if value.translation.width < -50 {
                        changeMonth(by: 1)
                    }
                }
        )
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

    private var monthOverview: some View {
        let currentBalance = accounts.reduce(0) { $0 + $1.currentBalanceCents }
        let unpaidIncome = filteredTransactions.filter { $0.type == .income && !$0.isPaid }.reduce(0) { $0 + $1.amountCents }
        let unpaidExpense = filteredTransactions.filter { $0.type == .expense && !$0.isPaid }.reduce(0) { $0 + $1.amountCents }
        let expectedBalance = currentBalance + unpaidIncome - unpaidExpense
        
        let monthIncome = filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amountCents }
        let monthExpense = filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amountCents }
        
        return VStack(spacing: 24) {
            HStack(spacing: 16) {
                overviewMetric(title: "Saldo Atual", amount: currentBalance, color: Theme.Colors.textPrimary)
                
                Divider()
                    .frame(height: 32)
                
                overviewMetric(title: "Previsto (Fim do Mês)", amount: expectedBalance, color: Theme.Colors.textSecondary)
            }
            .padding(.horizontal, 8)
            
            HStack(spacing: 16) {
                overviewCard(title: "Entradas", icon: "arrow.down.left", amount: monthIncome, color: Theme.Colors.success)
                overviewCard(title: "Saídas", icon: "arrow.up.right", amount: monthExpense, color: Theme.Colors.error)
            }
        }
    }
    
    private func overviewMetric(title: String, amount: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Theme.Typography.caption1)
                .secondaryTextColor()
            
            Text(formatCurrency(amount))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func overviewCard(title: String, icon: String, amount: Int, color: Color) -> some View {
        PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(color)
                    
                    Text(title)
                        .font(Theme.Typography.subheadline)
                        .primaryTextColor()
                }
                
                Text(formatCurrency(amount))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .primaryTextColor()
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func transactionRow(_ tx: Transaction) -> some View {
        let isDisintegrating = disintegratingTxIDs.contains(tx.persistentModelID)
        
        return ZStack {
            PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 12) {
                HStack {
                    // Category Icon (Temporary fallback to type-based icon)
                    Circle()
                        .fill(tx.type == .income ? Theme.Colors.success.opacity(0.2) : (tx.type == .expense ? Theme.Colors.error.opacity(0.2) : Theme.Colors.primary.opacity(0.2)))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: tx.type == .income ? "arrow.down.left" : (tx.type == .expense ? "arrow.up.right" : "arrow.left.arrow.right"))
                                .foregroundStyle(tx.type == .income ? Theme.Colors.success : (tx.type == .expense ? Theme.Colors.error : Theme.Colors.primary))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tx.title)
                            .font(Theme.Typography.headline)
                            .primaryTextColor()
                        Text(tx.account?.name ?? "Sem Conta")
                            .font(Theme.Typography.caption1)
                            .secondaryTextColor()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatCurrency(tx.amountCents))
                            .font(Theme.Typography.body)
                            .foregroundStyle(tx.type == .income ? Theme.Colors.success : (tx.type == .expense ? Theme.Colors.error : Theme.Colors.primary))
                        Text(tx.isPaid ? "Pago" : "Pendente")
                            .font(Theme.Typography.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(tx.isPaid ? Theme.Colors.success.opacity(0.2) : Theme.Colors.warning.opacity(0.2))
                            .foregroundStyle(tx.isPaid ? Theme.Colors.success : Theme.Colors.warning)
                            .clipShape(Capsule())
                    }
                }
            }
            .blur(radius: isDisintegrating ? 20 : 0)
            .scaleEffect(isDisintegrating ? 0.8 : 1.0)
            .opacity(isDisintegrating ? 0.0 : 1.0)
            .animation(.easeIn(duration: 0.25), value: isDisintegrating)
            
            if isDisintegrating {
                ParticleDustEffect()
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundStyle(Theme.Colors.primary.opacity(0.5))
            
            Text("Sem transações no mês")
                .font(Theme.Typography.title3)
                .primaryTextColor()
            
            Text("Você ainda não registrou nada neste mês.")
                .font(Theme.Typography.body)
                .secondaryTextColor()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, minHeight: 400, alignment: .center)
    }
    
    // MARK: - Helpers
    
    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedDate) {
            withAnimation(.spring) {
                selectedDate = newDate
            }
        }
    }
    
    private func formattedDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd 'de' MMMM"
        return formatter.string(from: date)
    }
    
    private func monthName(for date: Date) -> String {
        let calendar = Calendar.current
        let isCurrentYear = calendar.component(.year, from: date) == calendar.component(.year, from: Date())
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        
        if isCurrentYear {
            formatter.dateFormat = "MMMM"
            return formatter.string(from: date).capitalized
        } else {
            formatter.dateFormat = "MMM yyyy"
            return formatter.string(from: date).capitalized
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
}

// MARK: - Particle Effect
struct ParticleDustEffect: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Generate 35 particles for a dense dust effect
                ForEach(0..<35, id: \.self) { i in
                    let size = CGFloat.random(in: 2...5)
                    let startX = CGFloat.random(in: 0...geo.size.width)
                    let startY = CGFloat.random(in: 0...geo.size.height)
                    
                    let targetX = startX + CGFloat.random(in: 40...250)
                    let targetY = startY + CGFloat.random(in: -150...100)
                    let delay = Double.random(in: 0...0.3)
                    
                    Circle()
                        .fill(i % 3 == 0 ? Theme.Colors.primary : Theme.Colors.textSecondary)
                        .frame(width: size, height: size)
                        .position(x: animate ? targetX : startX, y: animate ? targetY : startY)
                        .scaleEffect(animate ? 0.1 : 1.0)
                        .opacity(animate ? 0.0 : 1.0)
                        .animation(.easeOut(duration: 0.5).delay(delay), value: animate)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            animate = true
        }
    }
}
