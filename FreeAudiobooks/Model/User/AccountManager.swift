//
//  AccountManager.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 15/01/2019.
//  Copyright © 2019 Ed Beecroft. All rights reserved.
//

import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import FirebaseFunctions
import SuperwallKit
import FirebaseAnalytics

class AccountManager {
	
	private init() {}
	static let shared = AccountManager()

    private lazy var functions = Functions.functions()
	
	var user: User?
	
	func userIsLoggedInButNotYetFetched() -> Bool {
		if userIsLoggedInToFirebase() && AccountManager.shared.user == nil {
			return true
		}
		return false
	}
	
	func userIsLoggedInToFirebase() -> Bool {
		if Auth.auth().currentUser == nil && Auth.auth().currentUser?.uid == nil {
			return false
		}
		return true
	}
	
	func syncFullUserWithId(_ uid: String,
							completion: ((Bool) -> ())?) {
		
		let userDispatchGroup = DispatchGroup()
		var success: Bool = true
		
		userDispatchGroup.enter()
		syncUserWithId(uid) { user in
			guard user != nil else {
				success = false
				userDispatchGroup.leave()
				return
			}
			userDispatchGroup.leave()
		}
		
		userDispatchGroup.notify(queue: .main) {
			DispatchQueue.main.async {
				completion?(success)
			}
		}
	}
	
	func syncUserWithId(_ uid: String,
						completion: @escaping (User?) -> ()) {
		
		let userData = Firestore.firestore()
            .collection(FirebasePaths.users.rawValue)
            .document(uid)
		userData.getDocument(source: .default) { snapshot, error in
			
			if
				let docSnapshot = snapshot,
				let dict = docSnapshot.data(),
				let user = User(dict: dict) {
				// User received successfully
				AccountManager.shared.user = user
                ListeningQuotaManager.shared.refresh(from: user)

				// Perform migration for savedItemsOrder if needed
				AccountManager.shared.migrateSavedItemsOrderIfNeeded()

				// Fire-and-forget: Check Brevo for actual subscription status
				EmailMarketingService().getSubscriptionStatus { subscribed in
					if let subscribed = subscribed {
						AccountManager.shared.user?.marketingPermission = subscribed

						// Persist to Firestore if subscribed (keeps Firestore in sync with Brevo)
						if subscribed {
							let data: [String: Any] = [
								FirebaseUserVariables.marketingPermission.rawValue: true
							]
							AccountManager.shared.updateUserWithData(data, completion: nil)
						}
					}
				}

				completion(user)
			} else {
				completion(nil)
			}
		}
	}
	
	func userAlreadyHasDocumentInDatabase(completion: @escaping (Bool) -> ()) {
		guard let uid = Auth.auth().currentUser?.uid else {
			completion(false)
			return
		}
		AccountManager.shared.syncFullUserWithId(uid, completion: { (success) in
			// This will complete false if the user hasn't already been uploaded to the database
			completion(success)
		})
	}
	
	// Adding new user for social logins
	func addNewDBUserForSocialLogin(firstName: String,
									lastName: String,
									email: String,
									signupMethod: String,
									appleUserIdentifier: String? = nil,
									completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let db = Firestore.firestore()

        // Determine the correct SignInMethod from the parameter
        let method: SignInMethod
        switch signupMethod.lowercased() {
        case "google":
            method = .google
        case "apple":
            method = .apple
        default:
            method = .apple
        }

        var data = UserManager.shared.buildInitialData(firstName: firstName,
                                                       lastName: lastName,
                                                       email: email,
                                                       uid: uid,
                                                       signInMethod: method)

        if let appleUserIdentifier = appleUserIdentifier {
            data[FirebaseUserVariables.appleUserIdentifier.rawValue] = appleUserIdentifier
        }

        db.collection(FirebasePaths.users.rawValue).document(uid).setData(data, completion: { (error) in
			if error != nil {
				completion(false)
				return
			} else {
				guard let uid = Auth.auth().currentUser?.uid else {
					completion(false)
					return
				}
				AccountManager.shared.syncFullUserWithId(uid, completion: { (success) in
					completion(success)
				})
			}
		})
	}

    func addNewDBUserForEmailRegistration(firstName: String,
                                          lastName: String,
                                          email: String,
                                          completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        let data = UserManager.shared.buildInitialData(firstName: firstName,
                                                       lastName: lastName,
                                                       email: email,
                                                       uid: uid,
                                                       signInMethod: .manual)

        Firestore.firestore()
            .collection(FirebasePaths.users.rawValue)
            .document(uid)
            .setData(data) { error in
                if error != nil {
                    completion(false)
                    return
                }

                AccountManager.shared.syncFullUserWithId(uid) { success in
                    completion(success)
                }
            }
    }
}

extension AccountManager {
	func setMarketingPermission(_ permission: Bool, amendedDate: Date) {
		user?.marketingPermission = permission
		user?.marketingConsentAmendedDate = amendedDate
	}
}

extension AccountManager {
	func userRegisteredWithEmail() -> Bool {
		if let user = user {
			return user.signInMethod == "manual"
		}
		return true
	}
}

// User updating
extension AccountManager {
    func updateUserWithData(_ data: [String: Any], completion: ((Bool) -> Void)?) {
		
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let ref = Firestore.firestore().collection(FirebasePaths.users.rawValue).document(uid)
		ref.setData(data, merge: true, completion: { (error) in
			if error != nil {
				completion?(false)
				return
			}
			completion?(true)
		})
	}
}

enum AccountProfileUpdateError: Error {
    case invalidFirstName
    case invalidLastName
    case invalidUsername
    case usernameTaken
    case notAuthenticated
    case serverError(String)

    var localizedDescription: String {
        switch self {
        case .invalidFirstName:
            return "Please enter a valid first name."
        case .invalidLastName:
            return "Please enter a valid last name."
        case .invalidUsername:
            return "Usernames must be 4-20 characters using only lowercase letters, numbers, or underscores."
        case .usernameTaken:
            return "That username is already taken. Please choose another."
        case .notAuthenticated:
            return "Please sign in again and try updating your profile."
        case .serverError(let message):
            return message
        }
    }
}

struct AccountProfileUpdateResponse {
    let firstName: String
    let lastName: String
    let username: String?
}

extension AccountManager {
    func updateProfile(
        firstName: String,
        lastName: String,
        username: String?,
        completion: @escaping (Result<AccountProfileUpdateResponse, AccountProfileUpdateError>) -> Void
    ) {
        let payload: [String: Any] = [
            FirebaseUserVariables.firstName.rawValue: firstName,
            FirebaseUserVariables.lastName.rawValue: lastName,
            FirebaseUserVariables.username.rawValue: username ?? NSNull()
        ]

        functions.httpsCallable("updateUserProfile").call(payload) { result, error in
            if let error = error {
                completion(.failure(.serverError(error.localizedDescription)))
                return
            }

            guard let data = result?.data as? [String: Any] else {
                completion(.failure(.serverError("We couldn't update your profile right now. Please try again.")))
                return
            }

            let success = data["success"] as? Bool ?? false
            guard success else {
                let errorCode = data["errorCode"] as? String ?? ""
                let message = data["message"] as? String ?? "We couldn't update your profile right now. Please try again."
                switch errorCode {
                case "invalid_first_name":
                    completion(.failure(.invalidFirstName))
                case "invalid_last_name":
                    completion(.failure(.invalidLastName))
                case "invalid_username":
                    completion(.failure(.invalidUsername))
                case "username_taken":
                    completion(.failure(.usernameTaken))
                case "not_authenticated":
                    completion(.failure(.notAuthenticated))
                default:
                    completion(.failure(.serverError(message)))
                }
                return
            }

            let resolvedFirstName = data[FirebaseUserVariables.firstName.rawValue] as? String ?? firstName
            let resolvedLastName = data[FirebaseUserVariables.lastName.rawValue] as? String ?? lastName
            let resolvedUsername = data[FirebaseUserVariables.username.rawValue] as? String
            completion(.success(AccountProfileUpdateResponse(firstName: resolvedFirstName,
                                                             lastName: resolvedLastName,
                                                             username: resolvedUsername)))
        }
    }
}

extension AccountManager {
    func queueReviewSnapshotRefresh(completion: ((Bool) -> Void)? = nil) {
        functions.httpsCallable("queueReviewDisplayNameBackfill").call { result, error in
            if let error {
                print("Failed to queue review snapshot refresh: \(error.localizedDescription)")
                completion?(false)
                return
            }

            let success = (result?.data as? [String: Any])?["success"] as? Bool ?? true
            completion?(success)
        }
    }

	func uploadProfileImage(image: UIImage,
							completion: @escaping (UploadImageResult) -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else {
			completion(.error)
			return
		}
		
		let existingProfileURL = AccountManager.shared.user?.profileImageURLString
		
		// Use a random string so we have a copy of each image that user uploaded
		let randomString = UUID().uuidString
		let storageRef = Storage.storage().reference()
			.child(FirebaseStoragePaths.users.rawValue)
			.child(uid)
			.child(FirebaseStoragePaths.profileImage.rawValue)
			.child(randomString)
		
		handleImageUploadForReference(storageRef, image: image, maxLongestSide: 600) { result in
			switch result {
            case .progress: break
			case .explicit, .error:
				completion(result)
			case .downloadURL(let urlString):
				let data = [FirebaseUserVariables.profileImageURLString.rawValue: urlString]
				AccountManager.shared.updateUserWithData(data) { success in
					if success {
						
						// Attempt to delete old images from storage to save space
						if let existingProfileURL = existingProfileURL {
							let storageRef = Storage.storage().reference(forURL: existingProfileURL)
							storageRef.delete(completion: nil)
						}
                        
						AccountManager.shared.user?.profileImageURLString = urlString
						AnalyticsManager.shared.trackUserSetProfileImage()
                        AccountManager.shared.queueReviewSnapshotRefresh()
						completion(.downloadURL(urlString))
					} else {
						storageRef.delete(completion: nil)
						completion(.error)
					}
				}
			}
		}
	}
}

// MARK: - Image Upload
extension AccountManager {
    func handleImageUploadForReference(_ storageRef: StorageReference,
                                       image: UIImage,
                                       maxLongestSide: CGFloat = 1000,
                                       compressionQuality: CGFloat = 0.7,
                                       includeExplicitContentCheck: Bool = true,
                                       completion: @escaping (UploadImageResult) -> Void) {
        
        storageRef.storage.maxUploadRetryTime = 120
        storageRef.storage.maxOperationRetryTime = 120
        
        var newUploadImage = image
        
        // We'll never want to resize the render, only the raw image
        if let resizedImage = image.resizeImageConstrainingLongestSide(maxLongestSide: maxLongestSide) {
            newUploadImage = resizedImage
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        if let imageData = newUploadImage.jpegData(compressionQuality: compressionQuality) {
            
            if includeExplicitContentCheck {
                ImageModerator.performExplicitContentCheckOn(imageData: imageData) { googleImageContentResult in
                    if googleImageContentResult == .error {
                        completion(.error)
                        return
                    } else if googleImageContentResult == .explicit {
                        completion(.explicit)
                        return
                    } else if googleImageContentResult == .notExplicit {
                        let uploadTask = storageRef.putData(imageData, metadata: metadata)
                        
                        // Add a progress observer to an upload task
                        uploadTask.observe(.progress) { snapshot in
                            if let progress = snapshot.progress {
                                let percentComplete = 100.0 * Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                                completion(.progress(percentComplete.roundedDouble(toPlaces: 2)))
                            }
                        }
                        
                        uploadTask.observe(.success) { snapshot in
                            // Upload completed successfully
                            snapshot.reference.downloadURL { url, error in
                                uploadTask.removeAllObservers()
                                if let urlString = url?.absoluteString {
                                    completion(.downloadURL(urlString))
                                } else {
                                    storageRef.delete(completion: nil)
                                    completion(.error)
                                    return
                                }
                            }
                        }
                        uploadTask.observe(.failure) { snapshot in
                            if let error = snapshot.error {
                                print("Image upload error: \(error)")
                            }
                            storageRef.delete(completion: nil)
                            completion(.error)
                            return
                        }
                    }
                }
            } else {
                let uploadTask = storageRef.putData(imageData, metadata: metadata)
                
                // Add a progress observer to an upload task
                uploadTask.observe(.progress) { snapshot in
                    if let progress = snapshot.progress {
                        let percentComplete = 100.0 * Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                        completion(.progress(percentComplete.roundedDouble(toPlaces: 2)))
                    }
                }
                
                uploadTask.observe(.success) { snapshot in
                    // Upload completed successfully
                    snapshot.reference.downloadURL { url, error in
                        uploadTask.removeAllObservers()
                        if let urlString = url?.absoluteString {
                            completion(.downloadURL(urlString))
                        } else {
                            storageRef.delete(completion: nil)
                            completion(.error)
                            return
                        }
                    }
                }
                uploadTask.observe(.failure) { snapshot in
                    storageRef.delete(completion: nil)
                    completion(.error)
                    return
                }
            }
        } else {
            completion(.error)
            return
        }
    }
}

enum UploadImageResult {
    case explicit
    case error
    case progress(Double)
    case downloadURL(String)
}

extension AccountManager {
	func pushNotificationsStatus(completion: @escaping ((UNAuthorizationStatus) -> Void)) {
		UNUserNotificationCenter.current().getNotificationSettings { settings in
			completion(settings.authorizationStatus)
		}
	}
}

extension AccountManager {
    static func signOut(tabBarController: AppTabBarController?) {
		
		if
			let providerId = Auth.auth().currentUser?.providerData.first?.providerID,
			providerId == "apple.com" {
			// Clear saved user ID
			AppleSignInUserDefaults.emailAddress = nil
			AppleSignInUserDefaults.givenName = nil
			AppleSignInUserDefaults.familyName = nil
			AppleSignInUserDefaults.appleUserId = nil
		}
		
		// Firebase
		let firebaseAuth = Auth.auth()
		do {
			try firebaseAuth.signOut()
            
            // Deletes push notification token
            let data: [String: Any] = [FirebaseUserVariables.fcmTokens.rawValue: [String]()]
            AccountManager.shared.updateUserWithData(data, completion: nil)
            
            DispatchQueue.main.async {
                UIApplication.shared.unregisterForRemoteNotifications()
            }
            
            AnalyticsManager.shared.trackUserLoggedOut()
            
            AccountManager.shared.user = nil
            AppDelegate.pnToken = nil
            
            SKReviewManager.clearCountData()
            
            AppNotifiers.shared.setReloadAll()
            
            // CoreDataManager.shared.clearAllData()
            
            ReadingUserDefaults.resetReadingPreferencesToDefaults()
            ReadingUserDefaults.clearOffsets()
            ReadingUserDefaults.clearResumeReading()
            AudioPositionManager.shared.clearAllPositions()

            // Clear all onboarding data so new sign-in starts fresh
            NewOnboardingCoordinator.shared.reset()

            // Clear email opt-in state so new sign-in starts fresh
            EmailOptInUserDefaults.reset()

            Superwall.shared.reset()
            // Purchases.shared.logOut(completion: nil)
		} catch let signOutError as NSError {
			print ("Error signing out: %@", signOutError)
		}
	}
}

extension AccountManager {
	var userIsSubscribed: Bool {
        if AppConstants.shared.developmentMode == .screenshots {
            return true
        } else {
            return Superwall.shared.subscriptionStatus.isActive
        }
	}
}

extension AccountManager {
	func updateSuperwallUserAttributes() {
		var attributes: [String: Any] = [
			"has_completed_onboarding": NewOnboardingUserDefaults.hasCompletedOnboarding()
		]

		if let user = AccountManager.shared.user {
			attributes["name"] = user.fullName()
			attributes["email"] = user.emailAddress.lowercased()
		}

		Superwall.shared.setUserAttributes(attributes) // (merges existing attributes)
	}
}

extension AccountManager {
    func deleteAllDataForCurrentUser(userUUID: String, completion: ((Bool) -> Void)?) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Optimistically delete any user images
        if let user = AccountManager.shared.user {
            if let imageURL = user.profileImageURLString {
                let storageRef = Storage.storage().reference(forURL: imageURL)
                storageRef.delete(completion: nil)
            }
        }
        
        // Delete the user
        let userRef = Firestore.firestore().collection(FirebasePaths.users.rawValue).document(uid)
        userRef.delete { error in
            if error != nil {
                completion?(false)
                return
            }
            completion?(true)
        }
        
        CoreDataManager.shared.clearAllData()
    }
}

enum CDBookSaveVenue {
    case story
    case today
}

extension AccountManager {
    func handleAutoSaveStoryWithUUIDIfNeeded(_ uuid: String,
                                             completion: @escaping (Bool) -> Void) {
        guard
            AccountManager.shared.userIsLoggedInToFirebase(),
            let user = AccountManager.shared.user else {
            completion(false)
            return
        }

        guard !user.savedStoryUUIDs.contains(uuid) else {
            completion(true)
            return
        }

        AccountManager.shared.user?.savedStoryUUIDs.append(uuid)
        AccountManager.shared.user?.savedItemsOrder.removeAll(where: { $0 == uuid })
        AccountManager.shared.user?.savedItemsOrder.append(uuid)

        let data: [String: FieldValue] = [
            FirebaseUserVariables.savedStoryUUIDs.rawValue: FieldValue.arrayUnion([uuid]),
            FirebaseUserVariables.savedItemsOrder.rawValue: FieldValue.arrayUnion([uuid])
        ]

        AccountManager.shared.updateUserWithData(data) { success in
            if !success {
                AccountManager.shared.user?.savedStoryUUIDs.removeAll(where: { $0 == uuid })
                AccountManager.shared.user?.savedItemsOrder.removeAll(where: { $0 == uuid })
            }
            completion(success)
        }
    }

    func handleAutoSaveBookInternalWithUUIDIfNeeded(_ uuid: String,
                                                    completion: @escaping (Bool) -> Void) {
        guard
            AccountManager.shared.userIsLoggedInToFirebase(),
            let user = AccountManager.shared.user else {
            completion(false)
            return
        }

        guard !user.savedBookInternalUUIDs.contains(uuid) else {
            completion(true)
            return
        }

        AccountManager.shared.user?.savedBookInternalUUIDs.append(uuid)
        AccountManager.shared.user?.savedItemsOrder.removeAll(where: { $0 == uuid })
        AccountManager.shared.user?.savedItemsOrder.append(uuid)

        let data: [String: FieldValue] = [
            FirebaseUserVariables.savedBookInternalUUIDs.rawValue: FieldValue.arrayUnion([uuid]),
            FirebaseUserVariables.savedItemsOrder.rawValue: FieldValue.arrayUnion([uuid])
        ]

        AccountManager.shared.updateUserWithData(data) { success in
            if !success {
                AccountManager.shared.user?.savedBookInternalUUIDs.removeAll(where: { $0 == uuid })
                AccountManager.shared.user?.savedItemsOrder.removeAll(where: { $0 == uuid })
            }
            completion(success)
        }
    }

    func handleSaveStoryWithUUID(_ uuid: String,
                                  save: Bool,
                                  saveVenue: CDBookSaveVenue,
                                  completion: @escaping () -> Void) {
        
        switch saveVenue {
        case .today:
            AppNotifiers.shared.shouldReloadSavedStoriesVC = true
        case .story:
            break
        }
        
        var data: [String: FieldValue]
        if save {
            AnalyticsManager.shared.trackBookSaved()
            data = [
                FirebaseUserVariables.savedStoryUUIDs.rawValue: FieldValue.arrayUnion([uuid]),
                FirebaseUserVariables.savedItemsOrder.rawValue: FieldValue.arrayUnion([uuid])
            ]
            
            AccountManager.shared.user?.savedItemsOrder.removeAll(where: { $0 == uuid })
            AccountManager.shared.user?.savedItemsOrder.append(uuid)
            
            HapticFeedbackHelper.shared.triggerLightImpactFeedback()
        } else {
            AnalyticsManager.shared.trackBookUnsaved()
            data = [
                FirebaseUserVariables.savedStoryUUIDs.rawValue: FieldValue.arrayRemove([uuid]),
                FirebaseUserVariables.savedItemsOrder.rawValue: FieldValue.arrayRemove([uuid])
            ]
            
            AccountManager.shared.user?.savedItemsOrder.removeAll(where: { $0 == uuid })
        }
        
        AccountManager.shared.updateUserWithData(data) { success in
            if !success {
                // Rollback local changes on failure
                if save {
                    AccountManager.shared.user?.savedStoryUUIDs.removeAll(where: { $0 == uuid })
                    AccountManager.shared.user?.savedItemsOrder.removeAll(where: { $0 == uuid })
                } else {
                    AccountManager.shared.user?.savedStoryUUIDs.append(uuid)
                    AccountManager.shared.user?.savedItemsOrder.append(uuid)
                }
            } else {
                // Nothing needed here
            }
            completion()
        }
    }
    
    enum CDBookInternalSaveVenue {
        case story
        case shortStoriesHomepage
        case today
    }
    
    func handleSaveBookInternal(_ cdBookInternal: CDBookInternal,
                                save: Bool,
                                saveVenue: CDBookInternalSaveVenue,
                                completion: @escaping () -> Void) {
        
        switch saveVenue {
        case .today:
            AppNotifiers.shared.shouldReloadSavedStoriesVC = true
        case .story, .shortStoriesHomepage:
            break
        }
        
        let uuid = cdBookInternal.contentUUID
        var data: [String: FieldValue]
        if save {
            AnalyticsManager.shared.trackBookInternalSaved(genre: cdBookInternal.genre)
            data = [
                FirebaseUserVariables.savedBookInternalUUIDs.rawValue: FieldValue.arrayUnion([uuid]),
                FirebaseUserVariables.savedItemsOrder.rawValue: FieldValue.arrayUnion([uuid])
            ]
            
            AccountManager.shared.user?.savedItemsOrder.removeAll(where: { $0 == uuid })
            AccountManager.shared.user?.savedItemsOrder.append(uuid)
            
            HapticFeedbackHelper.shared.triggerLightImpactFeedback()
        } else {
            AnalyticsManager.shared.trackBookInternalUnsaved()
            data = [
                FirebaseUserVariables.savedBookInternalUUIDs.rawValue: FieldValue.arrayRemove([uuid]),
                FirebaseUserVariables.savedItemsOrder.rawValue: FieldValue.arrayRemove([uuid])
            ]
            
            AccountManager.shared.user?.savedItemsOrder.removeAll(where: { $0 == uuid })
        }
        
        AccountManager.shared.updateUserWithData(data) { success in
            if !success {
                // Rollback local changes on failure
                if save {
                    AccountManager.shared.user?.savedBookInternalUUIDs.removeAll(where: { $0 == uuid })
                    AccountManager.shared.user?.savedItemsOrder.removeAll(where: { $0 == uuid })
                } else {
                    AccountManager.shared.user?.savedBookInternalUUIDs.append(uuid)
                    AccountManager.shared.user?.savedItemsOrder.append(uuid)
                }
            } else {
                // Nothing needed here
            }
            completion()
        }
    }
    
    // MARK: - Migration for savedItemsOrder
    func migrateSavedItemsOrderIfNeeded() {
        guard 
            let user = AccountManager.shared.user,
            user.savedItemsOrder.isEmpty,
            (!user.savedStoryUUIDs.isEmpty || !user.savedBookInternalUUIDs.isEmpty) else {
            return
        }
        
        // Create initial order from existing arrays (newest first, matching existing .reversed() pattern)
        let initialOrder = user.savedStoryUUIDs + user.savedBookInternalUUIDs
        
        let data: [String: Any] = [
            FirebaseUserVariables.savedItemsOrder.rawValue: initialOrder
        ]
        
        updateUserWithData(data) { success in
            if success {
                // Update local user object
                AccountManager.shared.user?.savedItemsOrder = initialOrder
                print("Successfully migrated savedItemsOrder for user")
            } else {
                print("Failed to migrate savedItemsOrder")
            }
        }
    }
}

extension AccountManager {
    func userHasCompletedBookWithUUID(_ storyUUID: String) -> Bool {
        return AccountManager.shared.user?.completedStoryUUIDs.contains(storyUUID) ?? false
    }
    func userHasCompletedBookInternalWithUUID(_ storyUUID: String) -> Bool {
        return AccountManager.shared.user?.completedBookInternalUUIDs.contains(storyUUID) ?? false
    }
}

extension AccountManager {
    func handleCompletedBookWithUUID(_ bookUUID: String,
                                      completed: Bool,
                                      completion: @escaping () -> Void) {

        let hasAlreadyMarkedCompleted = AccountManager.shared.userHasCompletedBookWithUUID(bookUUID)
        if completed && hasAlreadyMarkedCompleted {
            print("Has already marked completed")
            return completion()
        }

        var data: [String: FieldValue]

        if completed {
            // Local updates
            AccountManager.shared.user?.completedStoryUUIDs.append(bookUUID)
            AccountManager.shared.user?.weeklyBooksReadUUIDs.append(bookUUID)

            // Analytics
            AnalyticsManager.shared.trackBookCompleted()

            // Firestore data
            data = [
                FirebaseUserVariables.completedStoryUUIDs.rawValue: FieldValue.arrayUnion([bookUUID]),
                FirebaseUserVariables.weeklyBooksReadUUIDs.rawValue: FieldValue.arrayUnion([bookUUID])
            ]
        } else {
            // Local updates
            AccountManager.shared.user?.completedStoryUUIDs.removeAll(where: { $0 == bookUUID })
            AccountManager.shared.user?.weeklyBooksReadUUIDs.removeAll(where: { $0 == bookUUID })

            // Analytics
            AnalyticsManager.shared.trackBookUncompleted()

            // Firestore data
            data = [
                FirebaseUserVariables.completedStoryUUIDs.rawValue: FieldValue.arrayRemove([bookUUID]),
                FirebaseUserVariables.weeklyBooksReadUUIDs.rawValue: FieldValue.arrayRemove([bookUUID])
            ]
        }

        AccountManager.shared.updateUserWithData(data) { success in
            if !success {
                if completed {
                    AccountManager.shared.user?.completedStoryUUIDs.removeAll(where: { $0 == bookUUID })
                } else {
                    AccountManager.shared.user?.completedStoryUUIDs.append(bookUUID)
                }
            }
            completion()
        }
    }
    func handleCompletedBookInternal(_ cdBookInternal: CDBookInternal,
                                     completed: Bool,
                                     completion: @escaping () -> Void) {

        let storyUUID = cdBookInternal.contentUUID
        let hasAlreadyMarkedCompleted = AccountManager.shared.userHasCompletedBookInternalWithUUID(storyUUID)
        if completed && hasAlreadyMarkedCompleted {
            print("Has already marked completed")
            return completion()
        }

        var data: [String: FieldValue]

        if completed {
            // Local updates
            AccountManager.shared.user?.completedBookInternalUUIDs.append(storyUUID)
            AccountManager.shared.user?.weeklyBooksReadUUIDs.append(storyUUID)

            // Analytics
            AnalyticsManager.shared.trackBookInternalCompleted(cdBookInternal: cdBookInternal)

            // Firestore data
            data = [
                FirebaseUserVariables.completedBookInternalUUIDs.rawValue: FieldValue.arrayUnion([storyUUID]),
                FirebaseUserVariables.weeklyBooksReadUUIDs.rawValue: FieldValue.arrayUnion([storyUUID])
            ]
        } else {
            // Local updates
            AccountManager.shared.user?.completedBookInternalUUIDs.removeAll(where: { $0 == storyUUID })
            AccountManager.shared.user?.weeklyBooksReadUUIDs.removeAll(where: { $0 == storyUUID })

            // Analytics
            AnalyticsManager.shared.trackBookInternalUncompleted()

            // Firestore data
            data = [
                FirebaseUserVariables.completedBookInternalUUIDs.rawValue: FieldValue.arrayRemove([storyUUID]),
                FirebaseUserVariables.weeklyBooksReadUUIDs.rawValue: FieldValue.arrayRemove([storyUUID])
            ]
        }

        AccountManager.shared.updateUserWithData(data) { success in
            if !success {
                if completed {
                    AccountManager.shared.user?.completedBookInternalUUIDs.removeAll(where: { $0 == storyUUID })
                } else {
                    AccountManager.shared.user?.completedBookInternalUUIDs.append(storyUUID)
                }
            }
            completion()
        }
    }
}

// For email collection. Ensure this is not being called in any app submission.
//extension AccountManager {
//	func fetchAllUsers() {
//		let recipeQuery = Firestore
//			.firestore()
//			.collection(FirebasePaths.users.rawValue)
//
//		recipeQuery.getDocuments(source: .server) { snapshot, error in
//			guard let snapshot = snapshot else {
//				return
//			}
//
//			let users = snapshot.documents.compactMap { User(dict: $0.data()) }
//
//			var finalUsers = [User]()
//			users.forEach { user in
//				let whitespaceEmail = user.emailAddress.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//				let whitespaceName = user.firstName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//				if
//					!whitespaceEmail.isEmpty,
//					!whitespaceName.isEmpty,
//					user.marketingPermission == true {
//					finalUsers.append(user)
//				}
//			}
//
//
//			let date = Date.dateFromCustomString(customString: "02/06/2021")
//
//			finalUsers.removeAll(where: { $0.createdDate < date })
//
//			print("Total count: \(users.count)")
//			print("Final count: \(finalUsers.count)")
//
//			finalUsers.sort(by: { $0.createdDate > $1.createdDate })
//
//			finalUsers.forEach {
//				print($0.firstName)
//			}
//		}
//	}
//}
