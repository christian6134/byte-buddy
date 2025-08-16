import SwiftUI
import UserNotifications

struct YourGoalsView: View {
    @ObservedObject var foodManager: FirebaseFoodDataManager
    @State private var inputCalorie: String = ""
    @State private var inputProtein: String = ""
    @State private var inputCarb: String = ""
    @State private var inputSugar: String = ""
    @State private var inputFat: String = ""
    @State private var inputWeight: String = ""
    @State private var error: String?
    @State private var showingSuccessAlert = false
    // Reminder states
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var reminderMessage: String = "Don't forget to log your meals!"
    @State private var showingPermissionAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Centered, visually prominent title
                Text("My Goals")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)

                VStack(spacing: 24) {
                    // Calorie Goal
                    VStack(spacing: 8) {
                        Text("Daily Calorie Goal")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        HStack {
                            Spacer()
                            TextField(" Daily Calorie Goal", text: $inputCalorie)
                                .keyboardType(.numberPad)
                                .frame(width: 100)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Text("Calories")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    // Macro Totals
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Macro Totals")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(.bottom, 4)
                        HStack(spacing: 16) {
                            VStack {
                                TextField("Protein", text: $inputProtein)
                                    .keyboardType(.numberPad)
                                    .frame(width: 60)
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Text("g Protein")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                TextField("Carbs", text: $inputCarb)
                                    .keyboardType(.numberPad)
                                    .frame(width: 60)
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Text("g Carbs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                TextField("Sugar", text: $inputSugar)
                                    .keyboardType(.numberPad)
                                    .frame(width: 60)
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Text("g Sugar")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                TextField("Fat", text: $inputFat)
                                    .keyboardType(.numberPad)
                                    .frame(width: 60)
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Text("g Fat")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    // Optional Weight
                    VStack(alignment: .center, spacing: 8) {
                        Text("Weight (optional)")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        HStack {
                            Spacer()
                            TextField("Weight", text: $inputWeight)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Text("lb")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    // Reminder Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Reminder")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Toggle("Enable Reminder", isOn: $reminderEnabled)
                        if reminderEnabled {
                            DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                            TextField("Message", text: $reminderMessage)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    // Save Button
                    Button("Save") {
                        // Validate all fields
                        guard let cal = Double(inputCalorie), cal > 0, cal <= 10000 else {
                            error = "Calories: 1-10,000"
                            return
                        }
                        guard let protein = Double(inputProtein), protein >= 0, protein <= 1000 else {
                            error = "Protein: 0-1000g"
                            return
                        }
                        guard let carb = Double(inputCarb), carb >= 0, carb <= 1000 else {
                            error = "Carbs: 0-1000g"
                            return
                        }
                        guard let sugar = Double(inputSugar), sugar >= 0, sugar <= 500 else {
                            error = "Sugar: 0-500g"
                            return
                        }
                        guard let fat = Double(inputFat), fat >= 0, fat <= 500 else {
                            error = "Fat: 0-500g"
                            return
                        }
                        var weight: Double? = nil
                        if !inputWeight.trimmingCharacters(in: .whitespaces).isEmpty {
                            if let w = Double(inputWeight), w > 0, w <= 1000 {
                                weight = w
                            } else {
                                error = "Weight: 0-1000lb"
                                return
                            }
                        }
                        // Save goals
                        foodManager.updateGoals(
                            calorie: cal,
                            protein: protein,
                            carbs: carb,
                            sugar: sugar,
                            fat: fat,
                            weight: weight
                        )
                        // Save reminder settings
                        foodManager.updateReminderSettings(
                            enabled: reminderEnabled,
                            time: reminderTime,
                            message: reminderMessage
                        )
                        if reminderEnabled {
                            NotificationManager.shared.requestPermission { granted in
                                if granted {
                                    NotificationManager.shared.scheduleDailyReminder(at: reminderTime, message: reminderMessage)
                                } else {
                                    showingPermissionAlert = true
                                }
                            }
                        } else {
                            NotificationManager.shared.removeReminder()
                        }
                        error = nil
                        showingSuccessAlert = true
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                    .font(.headline)
                    if let error = error {
                        Text(error).foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                Spacer(minLength: 24)
            }
        }
        .onAppear {
            inputCalorie = String(Int(foodManager.dailyCalorieGoal))
            inputProtein = String(Int(foodManager.dailyProteinGoal))
            inputCarb = String(Int(foodManager.dailyCarbGoal))
            inputSugar = String(Int(foodManager.dailySugarGoal))
            inputFat = String(Int(foodManager.dailyFatGoal))
            if let w = foodManager.weight, w > 0 {
                inputWeight = String(Int(w))
            } else {
                inputWeight = ""
            }
            // Load reminder settings
            reminderEnabled = foodManager.reminderEnabled
            reminderTime = foodManager.reminderTime
            reminderMessage = foodManager.reminderMessage
        }
        .alert("Changes saved successfully", isPresented: $showingSuccessAlert) {
            Button("OK") { }
        }
        .alert("Notifications are disabled. Please enable them in Settings to receive reminders.", isPresented: $showingPermissionAlert) {
            Button("OK") { }
        }
    }
} 
