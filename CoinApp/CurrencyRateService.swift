//
//  CurrencyRateService.swift
//  CoinApp
//
//  Created by Zach Huang on 2025/7/5.
//

import Foundation

class CurrencyRateService: ObservableObject {
    @Published var rateToTWD: Double? = nil
    
    func fetchRate(from base: String, completion: @escaping (Double?) -> Void) {
        guard let url = URL(string: "https://v6.exchangerate-api.com/v6/21b5a016729d2fca980057b9/latest/\(base)") else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let data = data,
                let result = try? JSONDecoder().decode(ExchangeRateResponse.self, from: data),
                let rate = result.conversion_rates["TWD"]
            else {
                completion(nil)
                return
            }

            DispatchQueue.main.async {
                self.rateToTWD = rate
                completion(rate)
            }
        }.resume()
    }
}

struct ExchangeRateResponse: Codable {
    let conversion_rates: [String: Double]
}

