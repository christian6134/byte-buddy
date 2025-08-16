//
//  DashboardView.swift
//  Byte Buddy
//
//  Created by Garp on 6/28/25.
//

import SwiftUI
import FirebaseAuth

struct DashboardView: View {
    @ObservedObject var foodManager: FirebaseFoodDataManager
    @State private var showingLogoutAlert = false
    
    private var todaysTotals: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        foodManager.getDailyTotals(for: Date())
    }
    
    private var totalFoodsCreated: Int {
        foodManager.userFoods.count
    }
    
    private var todaysMealCount: Int {
        foodManager.getMealEntries(for: Date()).count
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Daily Summary Card
                NavigationLink(destination: EnhancedTodaysMealsView(foodManager: foodManager)) {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Today's Nutrition")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text("\(Int(todaysTotals.calories)) calories")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("\(todaysMealCount) meals logged")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        // Macro breakdown
                        HStack(spacing: 20) {
                            MacroIndicator(label: "P", value: Int(todaysTotals.protein), color: .red)
                            MacroIndicator(label: "C", value: Int(todaysTotals.carbs), color: .orange)
                            MacroIndicator(label: "F", value: Int(todaysTotals.fat), color: .purple)
                        }
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                }
                
                // Quick Actions Card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quick Actions")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Manage your nutrition")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.orange)
                    }
                    
                    HStack(spacing: 16) {
                        // Add Food Button
                        NavigationLink(destination: AddCustomFoodView(foodManager: foodManager)) {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                                
                                Text("Add Food")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // View Foods Button
                        NavigationLink(destination: MyFoodsView(foodManager: foodManager)) {
                            VStack(spacing: 8) {
                                Image(systemName: "list.bullet.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.green)
                                
                                Text("My Foods")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Stats Card
                VStack(spacing: 16) {
                    HStack {
                        Text("Your Progress")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.yellow)
                    }
                    
                    HStack(spacing: 30) {
                        VStack(spacing: 4) {
                            Text("\(totalFoodsCreated)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Foods Created")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(todaysMealCount)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("Today's Meals")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(Int(todaysTotals.calories))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("Calories Today")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                
                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue.opacity(0.1))
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout") {
                        showingLogoutAlert = true
                    }
                    .foregroundColor(.red)
                    .fontWeight(.medium)
                }
            }
            .alert("Logout", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            print("User logged out successfully")
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}

struct MacroIndicator: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.8))
            
            Text("\(value)g")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.3))
        .cornerRadius(8)
    }
}

// Wrapper to avoid naming conflicts
struct EnhancedTodaysMealsView: View {
    @ObservedObject var foodManager: FirebaseFoodDataManager
    
    var body: some View {
        TodaysMealsView(foodManager: foodManager)
    }
}

#Preview {
    DashboardView(foodManager: FirebaseFoodDataManager())
}
