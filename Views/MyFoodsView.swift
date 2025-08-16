//
//  MyFoodsView.swift
//  Byte Buddy
//


import SwiftUI

struct MyFoodsView: View {
    @ObservedObject var foodManager: FirebaseFoodDataManager
    @State private var showingDeleteAlert = false
    @State private var foodToDelete: Food?
    @State private var foodToEdit: Food?
    
    var body: some View {
        NavigationView {
            Group {
                if foodManager.isLoading && foodManager.userFoods.isEmpty {
                    // Show loading state
                    VStack {
                        ProgressView("Loading your foods...")
                        Text("This may take a moment")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                } else if foodManager.userFoods.isEmpty {
                    // Show empty state
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No foods added yet!")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        Text("Start by adding your first custom food in the 'Add Food' tab")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    // Show foods list
                    List {
                        ForEach(foodManager.userFoods) { food in
                            HStack {
                                // Left side: Food name and serving size
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(food.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(food.servingSize)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Right side: Calories
                                Text("\(Int(food.calories)) cal")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 2)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                foodToEdit = food
                            }
                        }
                        .onDelete(perform: deleteFood)
                    }
                    .refreshable {
                        // Pull to refresh
                        foodManager.refreshData()
                    }
                }
                
                // Show error message if theres a Firebase error
                if let errorMessage = foodManager.errorMessage {
                    VStack {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                        
                        Button("Retry") {
                            foodManager.refreshData()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("My Foods (\(foodManager.userFoods.count))")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if foodManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .sheet(item: $foodToEdit) { food in
                EditFoodSheet(
                    food: food,
                    foodManager: foodManager
                )
            }
        }
        .alert("Delete Food", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                foodToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let food = foodToDelete {
                    foodManager.deleteFood(food)
                    foodToDelete = nil
                }
            }
        } message: {
            if let food = foodToDelete {
                Text("Are you sure you want to delete '\(food.name)'? This action cannot be undone.")
            }
        }
    }
    
    private func deleteFood(at offsets: IndexSet) {
        // Show confirmation alert before deleting
        if let index = offsets.first {
            foodToDelete = foodManager.userFoods[index]
            showingDeleteAlert = true
        }
    }
}

struct EditFoodSheet: View {
    let food: Food
    @ObservedObject var foodManager: FirebaseFoodDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var foodName: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @State private var servingSize: String
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(food: Food, foodManager: FirebaseFoodDataManager) {
        self.food = food
        self.foodManager = foodManager
        
        // Initialize with current values
        self._foodName = State(initialValue: food.name)
        self._calories = State(initialValue: String(Int(food.calories)))
        self._protein = State(initialValue: String(Int(food.protein)))
        self._carbs = State(initialValue: String(Int(food.carbs)))
        self._fat = State(initialValue: String(Int(food.fat)))
        self._servingSize = State(initialValue: food.servingSize)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Food Information")) {
                    TextField("Food Name", text: $foodName)
                    TextField("Serving Size", text: $servingSize)
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
            }
            .navigationTitle("Edit Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateFood()
                    }
                    .disabled(foodName.isEmpty || calories.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func updateFood() {
        guard !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Please enter a food name"
            showingAlert = true
            return
        }
        
        guard let caloriesValue = Double(calories), caloriesValue >= 0 else {
            alertMessage = "Please enter a valid calorie amount"
            showingAlert = true
            return
        }
        
        let proteinValue = Double(protein) ?? 0
        let carbValue = Double(carbs) ?? 0
        let fatValue = Double(fat) ?? 0
        let servingSizeValue = servingSize.isEmpty ? "1 serving" : servingSize
        
        var updatedFood = food
        updatedFood.name = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedFood.calories = caloriesValue
        updatedFood.protein = proteinValue
        updatedFood.carbs = carbValue
        updatedFood.fat = fatValue
        updatedFood.servingSize = servingSizeValue
        
        dismiss()
    }
}

#Preview {
    MyFoodsView(foodManager: FirebaseFoodDataManager())
}
