//
//  EnhancedFoodSelectionSheet.swift
//  Byte Buddy
//
//  Created by Garp on 7/11/25.
//


//
//  Enhanced Food Selection with Nutritionix Search
//  Replace your existing EnhancedFoodSelectionSheet
//

import SwiftUI

struct EnhancedFoodSelectionSheet: View {
    @ObservedObject var foodManager: FirebaseFoodDataManager
    let selectedMealType: MealType
    let selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFood: Food?
    @State private var selectedNutritionixFood: NutritionixFood?
    @State private var quantity: String = "1.0"
    @State private var showingQuantityInput = false
    @State private var selectedTab = 0
    @State private var searchQuery = ""
    
    // Success feedback states
    @State private var showingSuccessMessage = false
    @State private var lastAddedFoodName = ""
    
    @StateObject private var nutritionixService = NutritionixService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("Food Source", selection: $selectedTab) {
                    Text("My Foods").tag(0)
                    Text("Search Database").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                if selectedTab == 0 {
                    // MY FOODS TAB (existing functionality)
                    myFoodsContent
                } else {
                    // SEARCH DATABASE TAB (new functionality)
                    searchDatabaseContent
                }
            }
            .navigationTitle("Add to \(selectedMealType.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay(
                // Success message overlay
                VStack {
                    if showingSuccessMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Added \(lastAddedFoodName)")
                                .fontWeight(.medium)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 4)
                        .transition(.move(edge: .top))
                    }
                    Spacer()
                }
                .animation(.easeInOut, value: showingSuccessMessage)
                .allowsHitTesting(false)
            )
        }
        .alert("Enter Quantity", isPresented: $showingQuantityInput) {
            TextField("Quantity", text: $quantity)
                .keyboardType(.decimalPad)
            
            Button("Add") {
                addMealEntry()
            }
            .disabled(quantity.isEmpty)
            
            Button("Cancel", role: .cancel) {
                selectedFood = nil
                selectedNutritionixFood = nil
                quantity = "1.0"
            }
        } message: {
            if let food = selectedFood {
                Text("How many servings of \(food.name)?")
            } else if let nutritionixFood = selectedNutritionixFood {
                Text("How many servings of \(nutritionixFood.food_name)?")
            }
        }
    }
    
    // My Foods Content (existing)
    private var myFoodsContent: some View {
        Group {
            if foodManager.userFoods.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("No foods available")
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    Text("Add some foods first in the 'Add Food' tab")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                List(foodManager.userFoods) { food in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(food.name)
                                .font(.headline)
                            Text(food.servingSize)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(food.calories)) cal")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFood = food
                        showingQuantityInput = true
                    }
                }
            }
        }
    }
    
    // Search Database Content (new)
    private var searchDatabaseContent: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search foods (e.g., 'grilled chicken breast')", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        performSearch()
                    }
                
                Button("Search") {
                    performSearch()
                }
                .disabled(searchQuery.isEmpty)
            }
            .padding()
            
            // Search Results
            if nutritionixService.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Searching food database...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else if let errorMessage = nutritionixService.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("Search Error")
                        .font(.headline)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        performSearch()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else if nutritionixService.searchResults.isEmpty && !searchQuery.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No Results Found")
                        .font(.headline)
                    
                    Text("Try searching for something like 'banana' or 'grilled chicken'")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else if searchQuery.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.blue.opacity(0.6))
                    
                    Text("Search Food Database")
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    Text("Search from over 1 million foods")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Try searching for:")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text("• 'banana'")
                        Text("• 'grilled chicken breast'")
                        Text("• 'mcdonald's big mac'")
                        Text("• '1 cup cooked rice'")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                // Search Results List
                List(nutritionixService.searchResults) { nutritionixFood in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(nutritionixFood.food_name)
                                .font(.headline)
                                .lineLimit(2)
                            
                            Text("\(nutritionixFood.serving_qty, specifier: "%.1f") \(nutritionixFood.serving_unit)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                Text("P: \(Int(nutritionixFood.nf_protein))g")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                
                                Text("C: \(Int(nutritionixFood.nf_total_carbohydrate))g")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                
                                Text("F: \(Int(nutritionixFood.nf_total_fat))g")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(Int(nutritionixFood.nf_calories)) cal")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            
                            Text("per serving")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedNutritionixFood = nutritionixFood
                        showingQuantityInput = true
                    }
                }
            }
        }
    }
    
    // Actions
    private func performSearch() {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            await nutritionixService.searchFood(query: searchQuery)
        }
    }
    
    private func addMealEntry() {
        guard let quantityValue = Double(quantity), quantityValue > 0 else { return }
        
        var foodName = ""
        
        if let food = selectedFood {
            // Add from My Foods
            foodManager.addMealEntry(
                food: food,
                quantity: quantityValue,
                mealType: selectedMealType,
                date: selectedDate
            )
            foodName = food.name
        } else if let nutritionixFood = selectedNutritionixFood {
            // Add from Nutritionix search
            guard let userId = foodManager.currentUserId else { return }
            let food = nutritionixFood.toFood(userId: userId)
            
            foodManager.addMealEntry(
                food: food,
                quantity: quantityValue,
                mealType: selectedMealType,
                date: selectedDate
            )
            foodName = nutritionixFood.food_name
        }
        
        // Show success feedback
        lastAddedFoodName = foodName
        showingSuccessMessage = true
        
        // Hide success message after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingSuccessMessage = false
        }
        
        // Reset selection and quantity but DON'T dismiss the sheet
        selectedFood = nil
        selectedNutritionixFood = nil
        quantity = "1.0"
    }
}
