//
//  TodaysMealsView.swift
//  Byte Buddy
//
//  Created by Garp on 6/27/25.
//

import SwiftUI

struct TodaysMealsView: View {
    @ObservedObject var foodManager: FirebaseFoodDataManager
    @State private var showingFoodSelection = false
    @State private var selectedMealType: MealType = .breakfast
    @State private var selectedDate = Date()
    private var dailyCalorieGoal: Double {
        foodManager.dailyCalorieGoal
    }
    
    private var todaysBreakfast: [MealEntry] {
        foodManager.getMealEntries(for: .breakfast, on: selectedDate)
    }
    
    private var todaysLunch: [MealEntry] {
        foodManager.getMealEntries(for: .lunch, on: selectedDate)
    }
    
    private var todaysDinner: [MealEntry] {
        foodManager.getMealEntries(for: .dinner, on: selectedDate)
    }
    
    private var dailyTotals: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        foodManager.getDailyTotals(for: selectedDate)
    }
    
    private var caloriesRemaining: Double {
        return dailyCalorieGoal - dailyTotals.calories
    }
    
    private var progressPercentage: Double {
        return min(dailyTotals.calories / dailyCalorieGoal, 1.0)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Date Picker
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding()
                    .background(Color(.systemGray6))
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Calories Remaining Header
                        CaloriesRemainingCard(
                            goal: dailyCalorieGoal,
                            consumed: dailyTotals.calories,
                            remaining: caloriesRemaining,
                            progress: progressPercentage
                        )
                        
                        // Daily Totals Summary
                        DailyTotalsCard(
                            calories: dailyTotals.calories,
                            protein: dailyTotals.protein,
                            carbs: dailyTotals.carbs,
                            fat: dailyTotals.fat
                        )
                        
                        // Meal Sections
                        EnhancedMealSectionView(
                            title: "Breakfast",
                            icon: "sunrise.fill",
                            iconColor: .orange,
                            mealEntries: todaysBreakfast,
                            onAddMeal: {
                                selectedMealType = .breakfast
                                showingFoodSelection = true
                            },
                            onDeleteEntry: { entry in
                                foodManager.deleteMealEntry(entry)
                            }
                        )
                        
                        EnhancedMealSectionView(
                            title: "Lunch",
                            icon: "sun.max.fill",
                            iconColor: .yellow,
                            mealEntries: todaysLunch,
                            onAddMeal: {
                                selectedMealType = .lunch
                                showingFoodSelection = true
                            },
                            onDeleteEntry: { entry in
                                foodManager.deleteMealEntry(entry)
                            }
                        )
                        
                        EnhancedMealSectionView(
                            title: "Dinner",
                            icon: "moon.fill",
                            iconColor: .indigo,
                            mealEntries: todaysDinner,
                            onAddMeal: {
                                selectedMealType = .dinner
                                showingFoodSelection = true
                            },
                            onDeleteEntry: { entry in
                                foodManager.deleteMealEntry(entry)
                            }
                        )
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Today's Meals")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingFoodSelection) {
                EnhancedFoodSelectionSheet(
                    foodManager: foodManager,
                    selectedMealType: selectedMealType,
                    selectedDate: selectedDate
                )
            }
        }
    }
}

struct CaloriesRemainingCard: View {
    let goal: Double
    let consumed: Double
    let remaining: Double
    let progress: Double
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                
                Text("Calories Remaining")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // Progress Bar
            VStack(spacing: 8) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: progress > 1.0 ? .red : .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("\(Int(goal))")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Goal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("-")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 4) {
                        Text("\(Int(consumed))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("Food")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("=")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 4) {
                        Text("\(Int(remaining))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(remaining < 0 ? .red : .green)
                        Text("Remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct DailyTotalsCard: View {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Daily Totals")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 30) {
                MacroColumn(
                    value: Int(calories),
                    unit: "",
                    label: "Calories",
                    color: .blue
                )
                
                MacroColumn(
                    value: Int(protein),
                    unit: "g",
                    label: "Protein",
                    color: .red
                )
                
                MacroColumn(
                    value: Int(carbs),
                    unit: "g",
                    label: "Carbs",
                    color: .orange
                )
                
                MacroColumn(
                    value: Int(fat),
                    unit: "g",
                    label: "Fat",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MacroColumn: View {
    let value: Int
    let unit: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)\(unit)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct EnhancedMealSectionView: View {
    let title: String
    let icon: String
    let iconColor: Color
    let mealEntries: [MealEntry]
    let onAddMeal: () -> Void
    let onDeleteEntry: (MealEntry) -> Void
    
    private var totalCalories: Double {
        mealEntries.reduce(0) { $0 + $1.totalCalories }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title2)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !mealEntries.isEmpty {
                    Text("\(Int(totalCalories)) cal")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            
            if mealEntries.isEmpty {
                Text("No meals added today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
            } else {
                ForEach(mealEntries) { entry in
                    MealEntryRow(entry: entry, onDelete: { onDeleteEntry(entry) })
                }
            }
            
            Button(action: onAddMeal) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                    Text("Add Food")
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
            }
            .padding(.leading, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MealEntryRow: View {
    let entry: MealEntry
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.foodName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Qty: \(entry.quantity, specifier: "%.1f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(entry.totalCalories)) cal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Button("Delete") {
                    onDelete()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    TodaysMealsView(foodManager: FirebaseFoodDataManager())
}
