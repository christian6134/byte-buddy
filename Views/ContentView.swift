

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var foodManager = FirebaseFoodDataManager()
    @State private var isUserAuthenticated = false
    
    var body: some View {
        Group {
            if isUserAuthenticated {
                TabView {
                    // Dashboard Tab
                    DashboardView(foodManager: foodManager)
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Dashboard")
                        }
                    
                    // Tab for Meals eaten today
                    TodaysMealsView(foodManager: foodManager)
                        .tabItem {
                            Image(systemName: "fork.knife")
                            Text("Today's Meals")
                        }
                    
                    // Tab for Adding Custom Food
                    AddCustomFoodView(foodManager: foodManager)
                        .tabItem {
                            Image(systemName: "plus.circle")
                            Text("Create Food")
                        }
                    
                    // Tab for Viewing Food List
                    MyFoodsView(foodManager: foodManager)
                        .tabItem {
                            Image(systemName: "list.bullet")
                            Text("Created Foods")
                        }
                    // New Tab for Your Goals
                    YourGoalsView(foodManager: foodManager)
                        .tabItem {
                            Image(systemName: "target")
                            Text("Your Goals")
                        }
                }
            } else {
                AuthenticationView(isAuthenticated: $isUserAuthenticated)
            }
        }
        .onAppear {
            checkAuthenticationStatus()
        }
    }
    
    private func checkAuthenticationStatus() {
        // Check if user is already logged in
        isUserAuthenticated = Auth.auth().currentUser != nil
        
        // Listen for authentication changes
        Auth.auth().addStateDidChangeListener { _, user in
            DispatchQueue.main.async {
                isUserAuthenticated = user != nil
            }
        }
    }
}

#Preview {
    ContentView()
}
