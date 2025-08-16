import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Food Model
struct Food: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var servingSize: String
    var dateAdded: Date
    var userId: String
    
    init(name: String, calories: Double, protein: Double, carbs: Double, fat: Double, servingSize: String, userId: String) {
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
        self.dateAdded = Date()
        self.userId = userId
    }
}

// MARK: - Meal Entry Model
struct MealEntry: Identifiable, Codable {
    @DocumentID var id: String?
    var foodId: String
    var foodName: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var quantity: Double
    var mealType: MealType
    var dateConsumed: Date
    var userId: String
    
    var totalCalories: Double {
        return calories * quantity
    }
    
    var totalProtein: Double {
        return protein * quantity
    }
    
    var totalCarbs: Double {
        return carbs * quantity
    }
    
    var totalFat: Double {
        return fat * quantity
    }
}

// MARK: - Meal Type Enum
enum MealType: String, CaseIterable, Codable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
}

// MARK: - Firebase Food Data Manager
class FirebaseFoodDataManager: ObservableObject {
    @Published var userFoods: [Food] = []
    @Published var mealEntries: [MealEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var dailyCalorieGoal: Double = 2000
    @Published var dailyProteinGoal: Double = 150
    @Published var dailyCarbGoal: Double = 250
    @Published var dailySugarGoal: Double = 40
    @Published var dailyFatGoal: Double = 70
    @Published var weight: Double? = nil
    @Published var reminderEnabled: Bool = false
    @Published var reminderTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var reminderMessage: String = "Don't forget to Feed your Buddy!"

    private let db = Firestore.firestore()
    private var foodsListener: ListenerRegistration?
    private var entriesListener: ListenerRegistration?
    private var userListener: ListenerRegistration?

    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    init() {
        // Set up authentication state listener
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if user != nil {
                    print("FirebaseFoodDataManager: User authenticated: \(user?.uid ?? "unknown")")
                    // User is authenticated, set up listeners
                    self?.setupListeners()
                    self?.setupUserListener()
                } else {
                    print("FirebaseFoodDataManager: User logged out")
                    // User logged out, remove listeners and clear data
                    self?.removeListeners()
                    self?.userFoods = []
                    self?.mealEntries = []
                    self?.userListener?.remove()
                    self?.dailyCalorieGoal = 2000
                }
            }
        }
    }
    
    deinit {
        removeListeners()
        userListener?.remove()
    }
    
    // MARK: - Real-time Listeners
    private func setupListeners() {
        guard let userId = currentUserId else { 
            print("FirebaseFoodDataManager: No current user ID, cannot set up listeners")
            return 
        }
        
        print("FirebaseFoodDataManager: Setting up listeners for user: \(userId)")
        
        // Remove existing listeners first
        removeListeners()
        
        // Listen to user's foods
        foodsListener = db.collection("foods")
            .whereField("userId", isEqualTo: userId)
            .order(by: "dateAdded", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("FirebaseFoodDataManager: Error loading foods: \(error.localizedDescription)")
                        self?.errorMessage = "Error loading foods: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { 
                        print("FirebaseFoodDataManager: No documents found")
                        return 
                    }
                    
                    print("FirebaseFoodDataManager: Received \(documents.count) food documents")
                    
                    self?.userFoods = documents.compactMap { document in
                        do {
                            let food = try document.data(as: Food.self)
                            print("FirebaseFoodDataManager: Successfully decoded food: \(food.name)")
                            return food
                        } catch {
                            print("FirebaseFoodDataManager: Failed to decode food document: \(error)")
                            return nil
                        }
                    }
                    
                    print("FirebaseFoodDataManager: Final userFoods count: \(self?.userFoods.count ?? 0)")
                }
            }
        
        // Listen to user's meal entries
        entriesListener = db.collection("mealEntries")
            .whereField("userId", isEqualTo: userId)
            .order(by: "dateConsumed", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = "Error loading meal entries: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    self?.mealEntries = documents.compactMap { document in
                        try? document.data(as: MealEntry.self)
                    }
                }
            }
    }
    
    private func removeListeners() {
        foodsListener?.remove()
        foodsListener = nil
        entriesListener?.remove()
        entriesListener = nil
    }

    private func setupUserListener() {
        guard let userId = currentUserId else { return }
        userListener?.remove()
        userListener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let data = snapshot?.data() else { return }
                if let goal = data["dailyCalorieGoal"] as? Double {
                    DispatchQueue.main.async { self?.dailyCalorieGoal = goal }
                }
                if let protein = data["dailyProteinGoal"] as? Double {
                    DispatchQueue.main.async { self?.dailyProteinGoal = protein }
                }
                if let carbs = data["dailyCarbGoal"] as? Double {
                    DispatchQueue.main.async { self?.dailyCarbGoal = carbs }
                }
                if let sugar = data["dailySugarGoal"] as? Double {
                    DispatchQueue.main.async { self?.dailySugarGoal = sugar }
                }
                if let fat = data["dailyFatGoal"] as? Double {
                    DispatchQueue.main.async { self?.dailyFatGoal = fat }
                }
                if let weight = data["weight"] as? Double {
                    DispatchQueue.main.async { self?.weight = weight }
                }
                if let reminderEnabled = data["reminderEnabled"] as? Bool {
                    DispatchQueue.main.async { self?.reminderEnabled = reminderEnabled }
                }
                if let reminderTimeString = data["reminderTime"] as? String,
                   let date = Self.timeStringToDate(reminderTimeString) {
                    DispatchQueue.main.async { self?.reminderTime = date }
                }
                if let reminderMessage = data["reminderMessage"] as? String {
                    DispatchQueue.main.async { self?.reminderMessage = reminderMessage }
                }
            }
    }

    static func timeStringToDate(_ time: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: time)
    }
    static func dateToTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    func updateReminderSettings(enabled: Bool, time: Date, message: String) {
        guard let userId = currentUserId else { return }
        let timeString = Self.dateToTimeString(time)
        db.collection("users").document(userId).setData([
            "reminderEnabled": enabled,
            "reminderTime": timeString,
            "reminderMessage": message
        ], merge: true)
    }
    
    func updateGoals(
        calorie: Double,
        protein: Double,
        carbs: Double,
        sugar: Double,
        fat: Double,
        weight: Double?
    ) {
        guard let userId = currentUserId else { return }
        var data: [String: Any] = [
            "dailyCalorieGoal": calorie,
            "dailyProteinGoal": protein,
            "dailyCarbGoal": carbs,
            "dailySugarGoal": sugar,
            "dailyFatGoal": fat
        ]
        if let weight = weight {
            data["weight"] = weight
        }
        db.collection("users").document(userId).setData(data, merge: true)
    }
    

    func addFood(_ food: Food) {
        guard let userId = currentUserId else { return }
        
        var newFood = food
        newFood.userId = userId
        
        isLoading = true
        
        do {
            // Create document reference first
            let docRef = db.collection("foods").document()
            
            // Set the ID before adding
            newFood.id = docRef.documentID
            
            // Now add the document
            try docRef.setData(from: newFood) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = "Error adding food: \(error.localizedDescription)"
                    } else {
                        // Add to UI with the Firebase ID
                        self?.userFoods.insert(newFood, at: 0)
                        print("✅ Food added with Firebase ID: \(docRef.documentID)")
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error adding food: \(error.localizedDescription)"
            }
        }
    }
    
    
    func deleteFood(_ food: Food) {
        guard let foodId = food.id else { return }
        
        isLoading = true
        
        // Delete from Firebase FIRST, then update UI on success
        db.collection("foods").document(foodId).delete { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Delete failed: \(error.localizedDescription)"
                } else {
                    // Only remove from UI after successful Firebase delete
                    if let index = self?.userFoods.firstIndex(where: { $0.id == foodId }) {
                        self?.userFoods.remove(at: index)
                    }
                }
            }
        }
    }
    
    
    
    
    
    
    // MARK: - Meal Entry Management
    func addMealEntry(food: Food, quantity: Double, mealType: MealType, date: Date = Date()) {
        guard let userId = currentUserId else { return }
        
        let entry = MealEntry(
            foodId: food.id ?? "",
            foodName: food.name,
            calories: food.calories,
            protein: food.protein,
            carbs: food.carbs,
            fat: food.fat,
            quantity: quantity,
            mealType: mealType,
            dateConsumed: date,
            userId: userId
        )
        
        isLoading = true
        
        do {
            _ = try db.collection("mealEntries").addDocument(from: entry) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = "Error adding meal entry: \(error.localizedDescription)"
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error adding meal entry: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteMealEntry(_ entry: MealEntry) {
        guard let entryId = entry.id else { return }
        
        isLoading = true
        
        db.collection("mealEntries").document(entryId).delete { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Error deleting meal entry: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Data Queries
    func getMealEntries(for date: Date) -> [MealEntry] {
        let calendar = Calendar.current
        return mealEntries.filter { calendar.isDate($0.dateConsumed, inSameDayAs: date) }
    }
    
    func getMealEntries(for mealType: MealType, on date: Date) -> [MealEntry] {
        let calendar = Calendar.current
        return mealEntries.filter {
            $0.mealType == mealType && calendar.isDate($0.dateConsumed, inSameDayAs: date)
        }
    }
    
    // MARK: - Daily Totals
    func getDailyTotals(for date: Date) -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let todaysEntries = getMealEntries(for: date)
        
        let totalCalories = todaysEntries.reduce(0) { $0 + $1.totalCalories }
        let totalProtein = todaysEntries.reduce(0) { $0 + $1.totalProtein }
        let totalCarbs = todaysEntries.reduce(0) { $0 + $1.totalCarbs }
        let totalFat = todaysEntries.reduce(0) { $0 + $1.totalFat }
        
        return (totalCalories, totalProtein, totalCarbs, totalFat)
    }
    
    // MARK: - User Management
    func refreshData() {
        // If user is authenticated, set up listeners again
        if currentUserId != nil {
            setupListeners()
            setupUserListener() // Re-setup user listener on refresh
        }
    }
}
