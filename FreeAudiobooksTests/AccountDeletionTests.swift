import XCTest
import UIKit
@testable import FreeAudiobooks

@MainActor
final class AccountDeletionTests: XCTestCase {
    func testInitialVerificationNoticeDoesNotDeleteAnything() {
        let screen = DeletionSpy()
        screen.handleDeleteAccount()
        let notice = screen.presentedNotice as? UIAlertController
        XCTAssertEqual(notice?.title, "Verification Required")
        XCTAssertEqual(notice?.actions.map(\.title), ["Cancel", "Continue"])
        XCTAssertNil(screen.verificationCompletion)
        XCTAssertTrue(screen.deletedUserIDs.isEmpty)
    }

    func testCancellationPreservesAccountAndStopsLoading() async {
        let screen = DeletionSpy()
        screen.performReauthenticationAndDelete()
        XCTAssertTrue(screen.deletedUserIDs.isEmpty)
        screen.verificationCompletion?(.failure(.cancelled))
        await drainMainQueue()
        XCTAssertTrue(screen.deletedUserIDs.isEmpty)
        XCTAssertEqual(screen.loadingStates, [true, false])
        XCTAssertTrue(screen.errors.isEmpty)
    }

    func testEveryVerificationFailurePreservesAccount() async {
        let failures: [ReauthenticationError] = [
            .missingCredential, .unknownSignInMethod, .userNotLoggedIn,
            .reauthenticationFailed(NSError(domain: "VerificationTest", code: 1))
        ]
        for failure in failures {
            let screen = DeletionSpy()
            screen.performReauthenticationAndDelete()
            screen.verificationCompletion?(.failure(failure))
            await drainMainQueue()
            XCTAssertTrue(screen.deletedUserIDs.isEmpty)
            XCTAssertEqual(screen.loadingStates.last, false)
            XCTAssertEqual(screen.errors.count, 1)
        }
    }

    func testDeletionWaitsForSuccessfulVerification() async {
        let screen = DeletionSpy()
        screen.performReauthenticationAndDelete()
        XCTAssertTrue(screen.deletedUserIDs.isEmpty)
        screen.verificationCompletion?(.success(()))
        await drainMainQueue()
        XCTAssertEqual(screen.deletedUserIDs, ["original-user"])
        XCTAssertTrue(screen.errors.isEmpty)
    }

    func testAccountSwitchDuringVerificationCannotDeleteEitherAccount() async {
        let screen = DeletionSpy()
        screen.performReauthenticationAndDelete()
        screen.userID = "different-user"
        screen.verificationCompletion?(.success(()))
        await drainMainQueue()
        XCTAssertTrue(screen.deletedUserIDs.isEmpty)
        XCTAssertEqual(screen.loadingStates.last, false)
        XCTAssertEqual(screen.errors.count, 1)
    }

    func testSignedOutUserCannotStartVerificationOrDeletion() {
        let screen = DeletionSpy()
        screen.userID = nil
        screen.performReauthenticationAndDelete()
        XCTAssertNil(screen.verificationCompletion)
        XCTAssertTrue(screen.deletedUserIDs.isEmpty)
        XCTAssertEqual(screen.errors.count, 1)
    }

    private func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}

private final class DeletionSpy: AccountDetailsViewController {
    var userID: String? = "original-user"
    var verificationCompletion: ((Result<Void, ReauthenticationError>) -> Void)?
    var deletedUserIDs: [String] = []
    var loadingStates: [Bool] = []
    var errors: [String] = []
    var presentedNotice: UIViewController?

    override var accountIDForDeletion: String? { userID }

    override func verifyIdentityForDeletion(completion: @escaping (Result<Void, ReauthenticationError>) -> Void) {
        verificationCompletion = completion
    }

    override func deleteVerifiedAccount(userID: String) {
        // Intercept before any real marketing, Storage, Firestore or Auth mutation.
        deletedUserIDs.append(userID)
    }

    override func showLoadingIndicator(show: Bool) { loadingStates.append(show) }
    override func showReauthenticationError(message: String) { errors.append(message) }
    override func showUnableToDeleteError() { errors.append("Unable to delete") }

    override func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        presentedNotice = viewControllerToPresent
        completion?()
    }
}
