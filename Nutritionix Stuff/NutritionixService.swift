//
//  NutritionixService.swift
//  Byte Buddy
//


import Foundation

// Model for Nutritionix API Response
struct NutritionixFood: Codable, Identifiable {
    let id = UUID()
    let food_name: String
    let serving_qty: Double
    let serving_unit: String
    let nf_calories: Double
    let nf_protein: Double
    let nf_total_carbohydrate: Double
    let nf_total_fat: Double
    
    // Convert to our OUR Food model
    func toFood(userId: String) -> Food {
        return Food(
            name: food_name,
            calories: nf_calories,
            protein: nf_protein,
            carbs: nf_total_carbohydrate,
            fat: nf_total_fat,
            servingSize: "\(serving_qty) \(serving_unit)",
            userId: userId
        )
    }
}

struct NutritionixResponse: Codable {
    let foods: [NutritionixFood]
}

// Service Class for Nutritionix
class NutritionixService: ObservableObject {
    @Published var searchResults: [NutritionixFood] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // "scout" function that searches for food
    func searchFood(query: String) async {
        // Update UI to show loading
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            searchResults = []
        }
        
        // Prepare the API request
        guard let url = URL(string: "\(API_Keys.nutritionixBaseURL)/natural/nutrients") else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Invalid URL"
            }
            return
        }
        
        // Step 3: Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add headers for Request (POST REQUEST) with Authentication headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(API_Keys.nutritionix_API_id, forHTTPHeaderField: "x-app-id")
        request.setValue(API_Keys.nutritionix_API_key, forHTTPHeaderField: "x-app-key")
        
        // Create the search query add and it to the request body
        let body = ["query": query]
        
        do {
            // Convert our search to JSON
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            // Disaptch (Send the scout) out to get information to Nutritionix servers
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Verify if "200" OK received
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                
                // Decode the information the scout brought back (JSON -> Swift Object)
                let nutritionixResponse = try JSONDecoder().decode(NutritionixResponse.self, from: data)
                
                // Update UI with the results
                await MainActor.run {
                    self.searchResults = nutritionixResponse.foods
                    self.isLoading = false
                }
                
            } else {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Search failed. Please try again."
                }
            }
            
        } catch {
            // Handle any errors
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Search error: \(error.localizedDescription)"
            }
        }
    }
}
