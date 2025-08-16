# byte-buddy


**Byte Buddy (iOS • SwiftUI)**
A simple nutrition & meal-tracking app built with SwiftUI. It uses:
- Firebase (Auth/Firestore) for data & auth
- Nutritionix API for food search
- Local notifications

**Requirements:**
- macOS (Sonoma or newer recommended)
- Xcode 15+ (with iOS 17+ SDK)
- Apple ID added in Xcode (for signing the app to run on devices/simulator)


**Quick Start (TL;DR)**
- Clone the repo and open the project in Xcode.
- Add secrets (Nutritionix keys) via Secrets.plist
- Make sure Firebase is configured (GoogleService-Info.plist present).
- Set a unique bundle ID
- Build & Run on an iPhone Simulator (Xcode Simulator).


**PROJECT STRUCTURE**
```text
Byte Buddy/
├─ Sources/
│  ├─ App/
│  │  └─ Byte_BuddyApp.swift                 # SwiftUI app entry point
│  │
│  ├─ Views/                                 # UI screens & sheets
│  │  ├─ AuthenticationView.swift
│  │  ├─ DashboardView.swift
│  │  ├─ TodaysMealsView.swift
│  │  ├─ MyFoodsView.swift
│  │  ├─ YourGoalsView.swift
│  │  ├─ EnhancedFoodSelectionSheet.swift
│  │  └─ AddCustomFoodView.swift
│  │
│  ├─ Services/                              # Networking, data, notifications
│  │  ├─ NutritionixService.swift            # Calls to Nutritionix API
│  │  ├─ FirebaseFoodDataManager.swift       # Firestore data layer
│  │  └─ NotificationManager.swift           # Local notifications
│  │
│  ├─ Models/                                # Data models (add as needed)
│  │  ├─ Food.swift
│  │  ├─ Meal.swift
│  │  └─ UserProfile.swift
│  │
│  └─ Resources/
│     ├─ GoogleService-Info.plist            # Firebase iOS config (required)
│     └─ Secrets.plist                       # Nutritionix keys (gitignored)
│
├─ Tests/
│  └─ ByteBuddyTests.swift                   # Unit/UI tests (optional)
│
├─ .gitignore
├─ README.md
└─ LICENSE
```

**Firebase Setup**
- Confirm GoogleService-Info.plist is required and must be downloaded from Firebase console.
- Add to project target in Xcode, select “Copy items if needed.”


**Running the App**
- Choose an iPhone simulator (e.g., iPhone 15) in the toolbar.
- Press ⌘R or Product ▶ Run.
