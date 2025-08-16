//
//  AuthenticationView.swift
//  Byte Buddy
//


import SwiftUI
import FirebaseAuth

struct AuthenticationView: View {
    @Binding var isAuthenticated: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoginMode = true
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // App Logo/Title
                VStack(spacing: 8) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Byte Buddy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Track your nutrition journey")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Authentication Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.none)
                        .disableAutocorrection(true)
                        .autocorrectionDisabled()
                    
                    if !isLoginMode {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.none)
                            .disableAutocorrection(true)
                            .autocorrectionDisabled()
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Main Action Button
                    Button(action: authenticateUser) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isLoginMode ? "Log In" : "Sign Up")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isLoading || email.isEmpty || password.isEmpty || (!isLoginMode && confirmPassword.isEmpty))
                    
                    // Toggle between login/signup
                    Button(action: {
                        isLoginMode.toggle()
                        errorMessage = ""
                        confirmPassword = ""
                    }) {
                        Text(isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Log In")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // REMOVED: Guest Mode functionality
            }
            .navigationBarHidden(true)
        }
    }
    
    private func authenticateUser() {
        // Clear any existing error
        errorMessage = ""
        isLoading = true
        
        // Validation
        guard !email.isEmpty, !password.isEmpty else {
            showError("Please fill in all fields")
            return
        }
        
        guard isValidEmail(email) else {
            showError("Please enter a valid email address")
            return
        }
        
        guard password.count >= 6 else {
            showError("Password must be at least 6 characters")
            return
        }
        
        if !isLoginMode {
            guard password == confirmPassword else {
                showError("Passwords do not match")
                return
            }
        }
        
        if isLoginMode {
            signIn()
        } else {
            signUp()
        }
    }
    
    private func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    showError(error.localizedDescription)
                } else {
                    isAuthenticated = true
                }
            }
        }
    }
    
    private func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    showError(error.localizedDescription)
                } else {
                    isAuthenticated = true
                }
            }
        }
    }
    
    // REMOVED: signInAnonymously function
    
    private func showError(_ message: String) {
        errorMessage = message
        isLoading = false
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

#Preview {
    AuthenticationView(isAuthenticated: .constant(false))
}
