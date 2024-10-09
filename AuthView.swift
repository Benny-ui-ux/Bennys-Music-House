import SwiftUI
import FirebaseAuth

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            Text(isSignUp ? "Sign Up" : "Sign In")
                .font(.custom("Menlo", size: 18))
                .fontWeight(.bold)
                .padding(.top, 40)
                .padding(.bottom, 20)
            
            TextField("Email", text: $email)
                .font(.custom("Menlo", size: 16))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            SecureField("Password", text: $password)
                .font(.custom("Menlo", size: 16))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                isSignUp ? signUp() : signIn()
            }) {
                Text(isSignUp ? "Sign Up" : "Sign In")
                    .font(.custom("Menlo", size: 18))
            }
            .padding()
            
            Button(action: {
                isSignUp.toggle()
            }) {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.custom("Menlo", size: 14))
            }
            .padding()
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.custom("Menlo", size: 14))
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }

    private func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                authViewModel.user = result?.user
            }
        }
    }

    private func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                authViewModel.user = result?.user
            }
        }
    }
}

