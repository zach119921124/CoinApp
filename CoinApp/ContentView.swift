//
//  ContentView.swift
//  CoinApp
//
//  Created by Zach Huang on 2025/2/18.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedCurrency = "TWD"
    @State private var coinCounts: [String: [String: String]] = UserDefaults.standard.dictionary(forKey: "coinCounts") as? [String: [String: String]] ?? [:]
    
    @FocusState private var isTextFieldFocused: Bool
    @State private var showAlert = false
    @State private var showCopiedText = false
    @StateObject private var rateService = CurrencyRateService()

    let maxTotal: Double = 99_999_999
    
    let currencyOptions = ["TWD", "JPY", "KRW", "CNY", "HKD", "SGD"]
    
    let currencyValues: [String: [String: Double]] = [
        "TWD": ["1": 1, "5": 5, "10": 10, "50": 50, "100": 100, "500": 500, "1000": 1000],
        "JPY": ["1": 1, "5": 5, "10": 10, "50": 50, "100": 100, "500": 500, "1000": 1000, "5000": 5000, "10000": 10000],
        "KRW": ["1": 1, "5": 5, "10": 10, "50": 50, "100": 100, "500": 500, "1000": 1000, "5000": 5000, "10000": 10000, "50000": 50000],
        "HKD": ["10": 10, "20": 20, "50": 50, "100": 100, "200": 200, "500": 500, "1000": 1000],
        "SGD": ["5": 5, "10": 10, "20": 20, "50": 50, "100": 100, "200": 200, "500": 500, "1000": 1000],
        "CNY": ["0.1": 0.1, "0.5": 0.5, "1": 1.0, "5": 5.0, "10": 10.0, "20": 20.0, "50": 50.0, "100": 100.0]
    ]
    
    var totalAmount: Double {
        let values = currencyValues[selectedCurrency] ?? [:]
        let counts = coinCounts[selectedCurrency] ?? [:]
        return values.reduce(0) { total, item in
            let count = Double(counts[item.key] ?? "0") ?? 0
            return total + (count * item.value)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Title
            HStack(alignment: .center, spacing: 10) {
                Text("Billy the Counter")
                    .font(.largeTitle.bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 5)
            .padding(.horizontal, 20)

            // Currency Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(currencyOptions, id: \.self) { currency in
                        Button(action: {
                            selectedCurrency = currency
                        }) {
                            Text("\(currencyFlag(for: currency)) \(currency)")
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedCurrency == currency ? Color(red: 1.0, green: 0.713, blue: 0.761) : Color.clear)
                                .foregroundColor(selectedCurrency == currency ? .white : Color.primary)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(red: 1.0, green: 0.713, blue: 0.761), lineWidth: selectedCurrency == currency ? 0 : 1)
                                )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .padding(.top, 5)
            }
            
            // Coin Input List
            List {
                let sortedKeys = currencyValues[selectedCurrency]!.keys.sorted {
                    Double($0)! < Double($1)!
                }

                ForEach(sortedKeys, id: \.self) { coin in
                    HStack(spacing: 12) {
                        Text("\(currencySymbol(for: selectedCurrency))\(coin)")
                            .font(.title2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField("0", text: Binding(
                            get: {
                                let value = coinCounts[selectedCurrency]?[coin] ?? "0"
                                return value == "0" ? "" : value
                            },
                            set: { newValue in
                                let filtered = newValue.filter { $0.isNumber }
                                if coinCounts[selectedCurrency] == nil {
                                    coinCounts[selectedCurrency] = [:]
                                }
                                coinCounts[selectedCurrency]?[coin] = String(filtered.prefix(6))
                                saveData()
                            }
                        ))
                        .keyboardType(.numberPad)
                        .focused($isTextFieldFocused)
                        .font(.title2)
                        .frame(width: 80)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.trailing)
                        .padding(12)
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(12)

                        Button(action: {
                            addTen(to: coin)
                        }) {
                            Text("+10")
                                .font(.title3)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(red: 1.0, green: 0.713, blue: 0.761))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 11)
                    .listRowInsets(EdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 10))
                }
            }
            .listStyle(.plain)
            
            // Total + Copy
            VStack(spacing: 6) {
                if showCopiedText {
                    Text("Copied!")
                        .font(.caption)
                        .foregroundColor(.green)
                        .transition(.opacity)
                }

                HStack {
                    Spacer()
                    Text("Total \(formattedTotalAmount())")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                    Spacer()
                    Button(action: {
                        UIPasteboard.general.string = formattedTotalAmount()
                        withAnimation {
                            showCopiedText = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showCopiedText = false
                            }
                        }
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                }

                // Converted to TWD
                HStack(spacing: 12) {
                    if selectedCurrency != "TWD", let rate = rateService.rateToTWD {
                        let twdEquivalent = totalAmount * rate
                        Text("≈ NT$\(Int(twdEquivalent))")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .onAppear {
                rateService.fetchRate(from: selectedCurrency) { _ in }
            }

            // Reset Button
            Button(action: resetCounts) {
                Text("Reset")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.6))
                    .cornerRadius(30)
                    .padding(.horizontal)
                    .padding(.top, 7)
                    .padding(.bottom, 3)
            }
        }
        .onChange(of: selectedCurrency) { newCurrency in
            rateService.fetchRate(from: newCurrency) { _ in }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isTextFieldFocused = false
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Wow! 💰"),
                message: Text("You are richer than I thought!"),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Logic

    func addTen(to coin: String) {
        let current = Int(coinCounts[selectedCurrency]?[coin] ?? "0") ?? 0
        let newCount = current + 10
        if coinCounts[selectedCurrency] == nil {
            coinCounts[selectedCurrency] = [:]
        }
        coinCounts[selectedCurrency]?[coin] = "\(newCount)"
        
        if totalAmount > maxTotal {
            showAlert = true
        }
        
        saveData()
    }
    
    func resetCounts() {
        coinCounts[selectedCurrency] = currencyValues[selectedCurrency]?.mapValues { _ in "0" } ?? [:]
        saveData()
    }
    
    func saveData() {
        UserDefaults.standard.set(coinCounts, forKey: "coinCounts")
    }
    
    func formattedTotalAmount() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        let formatted = formatter.string(from: NSNumber(value: totalAmount)) ?? "\(totalAmount)"
        return "\(currencySymbol(for: selectedCurrency))\(formatted)"
    }

    func currencySymbol(for code: String) -> String {
        switch code {
        case "TWD", "HKD", "SGD": return "$"
        case "JPY", "CNY": return "¥"
        case "KRW": return "₩"
        default: return code
        }
    }

    func currencyFlag(for code: String) -> String {
        switch code {
        case "TWD": return "🇹🇼"
        case "JPY": return "🇯🇵"
        case "KRW": return "🇰🇷"
        case "HKD": return "🇭🇰"
        case "SGD": return "🇸🇬"
        case "CNY": return "🇨🇳"
        default: return ""
        }
    }
}

#Preview {
    ContentView()
}
