//
//  ReauthenticationService.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 30/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn
import CryptoKit
import PopupDialog

enum ReauthenticationMethod {
    case manual
    case google
    case apple
}

enum ReauthenticationError: Error {
    case unknownSignInMethod
    case userNotLoggedIn
    case reauthenticationFailed(Error)
    case cancelled
    case missingCredential
}

class ReauthenticationService: NSObject {

    static let shared = ReauthenticationService()
    private override init() {}

    private weak var presentingViewController: UIViewController?
    private var completionHandler: ((Result<Void, ReauthenticationError>) -> Void)?

    // For Apple Sign In nonce
    private var currentNonce: String?

    /// Determines the user's sign-in method from their stored profile or Firebase provider data
    func getCurrentSignInMethod() -> ReauthenticationMethod? {
        // First check the user's stored signInMethod from Firestore
        if let user = AccountManager.shared.user {
            switch user.signInMethod {
            case SignInMethod.manual.rawValue:
                return .manual
            case SignInMethod.google.rawValue:
                return .google
            case SignInMethod.apple.rawValue:
                return .apple
            default:
                break
            }
        }

        // Fallback: Check Firebase provider data
        guard let providerData = Auth.auth().currentUser?.providerData else {
            return nil
        }

        for userInfo in providerData {
            switch userInfo.providerID {
            case "password":
                return .manual
            case "google.com":
                return .google
            case "apple.com":
                return .apple
            default:
                continue
            }
        }

        return nil
    }

    /// Main entry point for reauthentication
    func reauthenticate(from viewController: UIViewController,
                        completion: @escaping (Result<Void, ReauthenticationError>) -> Void) {
        self.presentingViewController = viewController
        self.completionHandler = completion

        guard Auth.auth().currentUser != nil else {
            completion(.failure(.userNotLoggedIn))
            return
        }

        guard let method = getCurrentSignInMethod() else {
            completion(.failure(.unknownSignInMethod))
            return
        }

        switch method {
        case .manual:
            showEmailPasswordReauthentication(from: viewController)
        case .google:
            performGoogleReauthentication(from: viewController)
        case .apple:
            performAppleReauthentication()
        }
    }

    // MARK: - Email/Password Reauthentication

    private func showEmailPasswordReauthentication(from viewController: UIViewController) {
        let reauthVC = ReauthenticateVC()

        let popup = PopupDialog(viewController: reauthVC,
                                buttonAlignment: .horizontal,
                                transitionStyle: .zoomIn,
                                panGestureDismissal: false)

        let cancelButton = CancelButton(title: "Cancel") { [weak self] in
            self?.completionHandler?(.failure(.cancelled))
        }

        let continueButton = DefaultButton(title: "Continue") { [weak self] in
            guard let self = self,
                  let email = reauthVC.emailTextField.text,
                  let password = reauthVC.passwordTextField.text,
                  !email.isEmpty,
                  !password.isEmpty else {
                self?.completionHandler?(.failure(.missingCredential))
                return
            }

            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            self.reauthenticateWithCredential(credential)
        }

        cancelButton.titleColor = Colours.grey140
        cancelButton.buttonColor = nil

        popup.addButtons([cancelButton, continueButton])
        viewController.present(popup, animated: true)
    }

    // MARK: - Google Reauthentication

    private func performGoogleReauthentication(from viewController: UIViewController) {
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    if (error as NSError).code == GIDSignInError.canceled.rawValue {
                        self.completionHandler?(.failure(.cancelled))
                    } else {
                        self.completionHandler?(.failure(.reauthenticationFailed(error)))
                    }
                }
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                DispatchQueue.main.async {
                    self.completionHandler?(.failure(.missingCredential))
                }
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            self.reauthenticateWithCredential(credential)
        }
    }

    // MARK: - Apple Reauthentication

    private func performAppleReauthentication() {
        let nonce = randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email, .fullName]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - Common Reauthentication

    private func reauthenticateWithCredential(_ credential: AuthCredential) {
        Auth.auth().currentUser?.reauthenticate(with: credential) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.completionHandler?(.failure(.reauthenticationFailed(error)))
                } else {
                    self?.completionHandler?(.success(()))
                }
            }
        }
    }

    // MARK: - Nonce Helpers (for Apple Sign In)

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension ReauthenticationService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            completionHandler?(.failure(.missingCredential))
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        reauthenticateWithCredential(credential)
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            completionHandler?(.failure(.cancelled))
        } else {
            completionHandler?(.failure(.reauthenticationFailed(error)))
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension ReauthenticationService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return presentingViewController?.view.window ?? UIWindow()
    }
}
