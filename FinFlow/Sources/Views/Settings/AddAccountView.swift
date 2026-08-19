import SwiftUI
import SwiftData

struct AccountColor: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let hex: String
}

let availableAccountColors: [AccountColor] = [
    AccountColor(name: "Laranja", hex: "#FF6B00"),
    AccountColor(name: "Amarelo", hex: "#FFCC00"),
    AccountColor(name: "Verde", hex: "#34C759"),
    AccountColor(name: "Ciano", hex: "#32ADE6"),
    AccountColor(name: "Azul", hex: "#007AFF"),
    AccountColor(name: "Índigo", hex: "#5856D6"),
    AccountColor(name: "Roxo", hex: "#AF52DE"),
    AccountColor(name: "Rosa", hex: "#FF2D55"),
    AccountColor(name: "Vermelho", hex: "#FF3B30"),
    AccountColor(name: "Marrom", hex: "#A2845E"),
    AccountColor(name: "Cinza", hex: "#8E8E93"),
    AccountColor(name: "Preto", hex: "#1A1A1A")
]

let financeIcons = [
    "building.columns.fill", "creditcard.fill", "wallet.pass.fill", "dollarsign.circle.fill", 
    "bag.fill", "chart.pie.fill", "briefcase.fill", "banknote.fill", "cart.fill", 
    "bitcoinsign.circle.fill", "centsign.circle.fill", "sterlingsign.circle.fill", 
    "yensign.circle.fill", "pills.fill", "cross.case.fill", "airplane", "car.fill", 
    "house.fill", "display", "macbook", "iphone", "gamecontroller.fill", 
    "graduationcap.fill", "book.fill", "fork.knife", "cup.and.saucer.fill",
    "gift.fill", "heart.fill", "star.fill", "bolt.fill", "flame.fill"
]

struct AddAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var initialBalanceCents: Int
    @State private var iconSystemName: String
    @State private var colorHex: String
    
    var accountToEdit: Account?
    
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
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // 1. Live Preview Card
                        previewCard
                            .padding(.top, 16)
                        
                        // 2. Huge Balance Input
                        monetaryInput
                        
                        // 1. Name Input
                        GlassTextField(title: "Nome da Conta", placeholder: "Ex: Nubank, Itaú, Carteira...", text: $name)
                        
                        // 2. Huge Monetary Inputte
                        colorPaletteSection
                        
                        // 5. Icon Selector
                        iconSelectorSection
                        
                        if let account = accountToEdit {
                            Button(role: .destructive) {
                                modelContext.delete(account)
                                dismiss()
                            } label: {
                                Text("Remover Conta")
                                    .font(Theme.Typography.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.Colors.error.opacity(0.15), in: .rect(cornerRadius: Theme.Layout.buttonCornerRadius))
                                    .foregroundStyle(Theme.Colors.error)
                            }
                            .padding(.top, 16)
                        }
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal)
                }
                .clipShape(Rectangle().inset(by: -100))
            }
            .navigationTitle(accountToEdit != nil ? "Editar Conta" : "Nova Conta")
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
        }
    }
    
    // MARK: - Components
    
    private var previewCard: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: 48, height: 48)
                
                Image(systemName: iconSystemName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name.isEmpty ? "Nome da Conta" : name)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(name.isEmpty ? Theme.Colors.textSecondary : Theme.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(formatCurrency(initialBalanceCents))
                    .font(Theme.Typography.body)
                    .secondaryTextColor()
            }
            
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(Color(hex: colorHex).opacity(isValid ? 1.0 : 0.0))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cardCornerRadius))
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
    
    private var colorPaletteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("COR DE IDENTIFICAÇÃO")
                    .font(Theme.Typography.caption1)
                    .secondaryTextColor()
                    .padding(.leading, 4)
                
                Spacer()
                
                if let selected = availableAccountColors.first(where: { $0.hex == colorHex }) {
                    Text(selected.name)
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(Color(hex: colorHex))
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    HStack(spacing: 16) {
                        ForEach(availableAccountColors) { accountColor in
                            let isSelected = colorHex == accountColor.hex
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    colorHex = accountColor.hex
                                }
                            }) {
                                Circle()
                                    .fill(Color(hex: accountColor.hex))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                                            .padding(2)
                                    )
                                    .shadow(color: Color(hex: accountColor.hex).opacity(isSelected ? 0.7 : 0.0), radius: 15, x: 0, y: 8)
                                    .scaleEffect(isSelected ? 1.2 : 1.0)
                            }
                            .buttonStyle(.plain)
                            .id(accountColor.hex)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 40)
                    .onAppear {
                        // Small delay to ensure the view is rendered before scrolling
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring) {
                                proxy.scrollTo(colorHex, anchor: .center)
                            }
                        }
                    }
                    .onChange(of: colorHex) { _, newValue in
                        withAnimation(.spring) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
            }
            .padding(.horizontal, -16)
            .padding(.vertical, -40)
        }
    }
    
    private var iconSelectorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ÍCONE")
                .font(Theme.Typography.caption1)
                .secondaryTextColor()
                .padding(.leading, 4)
            
            NavigationLink(destination: IconSelectionView(selectedIcon: $iconSystemName, themeColorHex: colorHex)) {
                HStack {
                    Image(systemName: iconSystemName)
                        .font(.system(size: 28))
                        .foregroundStyle(Color(hex: colorHex))
                        .frame(width: 40)
                    
                    Text("Mudar Ícone")
                        .font(Theme.Typography.body)
                        .primaryTextColor()
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .secondaryTextColor()
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
    
    private var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func save() {
        if let account = accountToEdit {
            account.name = name
            account.initialBalanceCents = initialBalanceCents
            account.iconSystemName = iconSystemName
            account.colorHex = colorHex
        } else {
            let newAccount = Account(
                name: name,
                initialBalanceCents: initialBalanceCents,
                iconSystemName: iconSystemName,
                colorHex: colorHex
            )
            modelContext.insert(newAccount)
        }
        dismiss()
    }
}

// MARK: - Icon Selection View
struct IconSelectionView: View {
    @Binding var selectedIcon: String
    var themeColorHex: String
    @Environment(\.dismiss) private var dismiss
    
    let columns = [GridItem(.adaptive(minimum: 70), spacing: 16)]
    
    var body: some View {
        BaseView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(financeIcons, id: \.self) { icon in
                        Button(action: {
                            withAnimation {
                                selectedIcon = icon
                                dismiss()
                            }
                        }) {
                            VStack {
                                Image(systemName: icon)
                                    .font(.system(size: 32))
                                    .frame(width: 70, height: 70)
                                    .background(
                                        Circle()
                                            .fill(selectedIcon == icon ? Color(hex: themeColorHex).opacity(0.2) : Theme.Colors.surfaceSolid)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(selectedIcon == icon ? Color(hex: themeColorHex) : Color.clear, lineWidth: 2)
                                    )
                                    .foregroundStyle(selectedIcon == icon ? Color(hex: themeColorHex) : Theme.Colors.textPrimary)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Escolher Ícone")
        .navigationBarTitleDisplayMode(.inline)
    }
}
