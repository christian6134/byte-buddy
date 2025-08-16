//
//  AddCustomFoodView.swift
//  Byte Buddy
//
//

import SwiftUI
import FirebaseAuth

struct AddCustomFoodView: View {
    // State variables (What the user will type in)
    @State private var foodName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var servingSize = ""
    
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @ObservedObject var foodManager: FirebaseFoodDataManager
    
    private func createFoodEntry() {
        // Check if user is authenticated
        guard let userId = Auth.auth().currentUser?.uid else {
            showAlert(title: "Authentication Error", message: "Please log in to add foods")
            return
        }
        
        let trimmedName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter a food name")
            return
        }
        
        // Fixed: Change >= 0 to > 0 to match the error message
        guard let caloriesValue = Double(calories), caloriesValue > 0 else {
            showAlert(title: "Invalid Calories", message: "Please enter a calorie amount (Must be > 0)")
            return
        }
        
        // Convert other nutritional values; if the user does not enter them, 0
        let proteinValue = Double(protein) ?? 0
        let carbValue = Double(carbs) ?? 0
        let fatValue = Double(fat) ?? 0
        let servingSizeValue = servingSize.isEmpty ? "1 serving" : servingSize
        
        // Create the Food Object with Firebase collection structure
        let newFood = Food(
            name: trimmedName,
            calories: caloriesValue,
            protein: proteinValue,
            carbs: carbValue,
            fat: fatValue,
            servingSize: servingSizeValue,
            userId: userId
        )
        
        // Add newFood using Firebase instead
        foodManager.addFood(newFood)
        clearForm()
        showAlert(title: "Successful Entry!", message: "\(trimmedName) has been logged.")
    }
    
    // Empties form for next entry
    private func clearForm() {
        foodName = ""
        calories = ""
        protein = ""
        carbs = ""
        fat = ""
        servingSize = ""
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }

    // UI
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // Show loading indicator when Firebase is processing
                if foodManager.isLoading {
                    ProgressView("Saving food...")
                        .padding()
                }
                
                // food Form
                Form {
                    Section(header: Text("Food Information")) {
                        TextField("Food Name (e.g., Banana)", text: $foodName)
                        TextField("Serving Size (e.g., '100g, 4oz, 300mL')", text: $servingSize)
                    }
                    
                    Section(header: Text("Nutritional Information Per Serving")) {
                        HStack {
                            Text("Calories")
                            Spacer()
                            TextField("0 cal", text: $calories)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Protein (g)")
                            Spacer()
                            TextField("0 g", text: $protein)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Carbs (g)")
                            Spacer()
                            TextField("0g", text: $carbs)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Fat (g)")
                            Spacer()
                            TextField("0g", text: $fat)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Section {
                        Button("Add Custom Food Entry") {
                            createFoodEntry()
                        }
                        .disabled(foodName.isEmpty || calories.isEmpty || foodManager.isLoading)
                        .frame(maxWidth: .infinity)
                    }
                }
                .navigationTitle("Add a Custom Food")
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onDisappear {
                clearForm() // Clear form when leaving this screen
            }
        }
    }
}

#Preview {
    AddCustomFoodView(foodManager: FirebaseFoodDataManager())
}
