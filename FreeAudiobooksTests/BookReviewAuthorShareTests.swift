import XCTest
import UIKit
import Cosmos
@testable import FreeAudiobooks

@MainActor
final class BookReviewAuthorShareTests: XCTestCase {
    func testBundledDefaultIsDisabled() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "RemoteConfigDefaults", withExtension: "plist"))
        let defaults = try XCTUnwrap(NSDictionary(contentsOf: url))
        XCTAssertEqual(defaults["shouldShowBookReviewAuthorShareAB"] as? Bool, false)
        XCTAssertEqual(defaults["bookCompletionShareButtonVariantAB"] as? String, "original")
        XCTAssertEqual(defaults["bookCompletionShareButtonTitleAB"] as? String, "Send")
        XCTAssertEqual(RCKeys.shouldShowBookReviewAuthorShareAB.rawValue, "shouldShowBookReviewAuthorShareAB")
        XCTAssertEqual(RCKeys.bookCompletionShareButtonVariantAB.rawValue, "bookCompletionShareButtonVariantAB")
        XCTAssertNil(defaults["shouldShowBookReviewAuthorShare"])
        XCTAssertNil(defaults["bookCompletionShareButtonVariant"])
    }

    func testControlAndInitiallyUncheckedTreatmentAcrossLayouts() throws {
        for variant in [BookReviewVariant.original, .originalRatingRequired, .reviewStyle] {
            let control = Fixture(showsCheckbox: false, variant: variant)
            XCTAssertNil(control.checkbox)
            let treatment = Fixture(showsCheckbox: true, variant: variant)
            let checkbox = try XCTUnwrap(treatment.checkbox)
            XCTAssertFalse(checkbox.isSelected)
            XCTAssertEqual(treatment.stars.rating, 0)
            XCTAssertEqual(treatment.feedback.superview?.alpha, 0)
            XCTAssertTrue(checkbox.isHidden)
            checkbox.sendActions(for: .touchUpInside)
            XCTAssertFalse(checkbox.isSelected)
            treatment.setRating(3)
            XCTAssertFalse(checkbox.isHidden)
            XCTAssertEqual(checkbox.alpha, 1)
            checkbox.updateConfiguration()
            XCTAssertEqual(checkbox.accessibilityLabel, "Share review with author")
            XCTAssertEqual(checkbox.accessibilityValue, "Unchecked")
            checkbox.sendActions(for: .touchUpInside)
            checkbox.updateConfiguration()
            XCTAssertTrue(checkbox.isSelected)
            XCTAssertEqual(checkbox.accessibilityValue, "Checked")
            XCTAssertTrue(checkbox.accessibilityTraits.contains(.selected))
            treatment.setRating(4)
            XCTAssertFalse(checkbox.isHidden)
            XCTAssertTrue(checkbox.isSelected)
            checkbox.sendActions(for: .touchUpInside)
            XCTAssertFalse(checkbox.isSelected)
            checkbox.sendActions(for: .touchUpInside)
            XCTAssertFalse(try XCTUnwrap(Fixture(showsCheckbox: true, variant: variant).checkbox).isSelected)

            let controlStack = try XCTUnwrap(control.feedback.superview?.superview as? UIStackView)
            let treatmentStack = try XCTUnwrap(checkbox.superview as? UIStackView)
            XCTAssertEqual(treatmentStack.arrangedSubviews.count, controlStack.arrangedSubviews.count + 1)
            XCTAssertTrue(treatmentStack.arrangedSubviews.last === checkbox)
            XCTAssertEqual(treatmentStack.spacing, controlStack.spacing)
        }
    }

    func testExposureOnlyOnFirstAppearanceWithCapturedContext() {
        let fixture = Fixture(showsCheckbox: true, variant: .reviewStyle, type: .bookInternalAudiobook)
        XCTAssertTrue(fixture.events.isEmpty)
        fixture.popup.viewDidAppear(false)
        fixture.popup.viewDidAppear(false)
        let exposures = fixture.events.filter { $0.name == "enhancedBookCompletionViewed" }
        XCTAssertEqual(exposures.count, 1)
        XCTAssertEqual(exposures.first?.parameters, [
            "author_share_variant": "checkbox",
            "book_review_variant": "reviewStyle",
            "content_type": "bookInternalAudiobook"
        ])
    }

    func testSuccessEventsAcrossContentTypesCommentsAndSelection() throws {
        // The metadata deliberately has no internal genre, exercising the former early-return path.
        for type in [ReviewedContentType.bookInternal, .bookInternalAudiobook] {
            for comment in ["", " \n\t ", "A memorable ending."] {
                for selection in [false, true] {
                    for isUpdate in [false, true] {
                        let fixture = Fixture(showsCheckbox: true, type: type)
                        fixture.setRating(3)
                        fixture.feedback.text = comment
                        if selection { fixture.checkbox?.sendActions(for: .touchUpInside) }
                        fixture.continueButton.sendActions(for: .touchUpInside)
                        XCTAssertEqual(fixture.requests.count, 1)
                        XCTAssertTrue(fixture.events.isEmpty)
                        let request = try XCTUnwrap(fixture.requests.first)
                        XCTAssertEqual(request.rating, 3)
                        XCTAssertEqual(request.type, type)
                        XCTAssertEqual(request.comment, comment.isEmpty ? nil : comment)
                        request.complete(.success(SubmitBookReviewResponse(success: true, newRating: 3, newNumberOfRatings: 1, isUpdate: isUpdate)))
                        let hasComment = !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        var expected = ["bookRated"]
                        if hasComment { expected.append("bookRatedWithComment") }
                        if selection { expected.append("bookRatedWithAuthorShare") }
                        XCTAssertEqual(fixture.outcomes.map(\.name), expected)
                        for event in fixture.outcomes {
                            XCTAssertEqual(event.parameters, [
                                "author_share_variant": "checkbox",
                                "book_review_variant": "original",
                                "content_type": type.rawValue,
                                "rating": "3",
                                "has_comment": hasComment ? "1" : "0",
                                "author_share_selected": selection ? "1" : "0",
                                "is_update": isUpdate ? "1" : "0"
                            ])
                        }
                    }
                }
            }
        }
    }

    func testControlCountsCommentsWithoutAuthorShare() throws {
        let fixture = Fixture(showsCheckbox: false)
        fixture.setRating(3)
        fixture.feedback.text = "Good book"
        fixture.continueButton.sendActions(for: .touchUpInside)
        try XCTUnwrap(fixture.requests.first).complete(.success(SubmitBookReviewResponse(success: true, newRating: 3, newNumberOfRatings: 1, isUpdate: false)))
        XCTAssertEqual(fixture.outcomes.map(\.name), ["bookRated", "bookRatedWithComment"])
        XCTAssertEqual(fixture.outcomes.first?.parameters["author_share_variant"], "control")
        XCTAssertEqual(fixture.outcomes.first?.parameters["author_share_selected"], "0")
    }

    func testFailedAndUnconfirmedSavesDoNotEmitOutcomes() throws {
        for result in [
            ContentRatingManager.BookReviewResult.failed(.networkError(NSError(domain: "test", code: 1))),
            .success(SubmitBookReviewResponse(success: false, newRating: 0, newNumberOfRatings: 0, isUpdate: false))
        ] {
            let fixture = Fixture(showsCheckbox: true)
            fixture.setRating(3)
            fixture.feedback.text = "Good book"
            fixture.checkbox?.sendActions(for: .touchUpInside)
            fixture.continueButton.sendActions(for: .touchUpInside)
            try XCTUnwrap(fixture.requests.first).complete(result)
            XCTAssertTrue(fixture.events.isEmpty)
        }
    }

    func testNoRatingContinuesWithoutSubmissionOrRevealingCheckbox() {
        let fixture = Fixture(showsCheckbox: true)
        fixture.checkbox?.sendActions(for: .touchUpInside)
        XCTAssertEqual(fixture.checkbox?.isSelected, false)
        fixture.continueButton.sendActions(for: .touchUpInside)
        fixture.continueButton.sendActions(for: .touchUpInside)
        XCTAssertTrue(fixture.requests.isEmpty)
        XCTAssertTrue(fixture.outcomes.isEmpty)
        XCTAssertEqual(fixture.checkbox?.isHidden, true)
        XCTAssertEqual(fixture.events.filter { $0.name == "enhancedBookCompletionShareViewed" }.count, 1)
    }

    func testInFlightSubmissionIsDeduplicatedAndUsesSnapshot() throws {
        let fixture = Fixture(showsCheckbox: true)
        fixture.setRating(3)
        fixture.feedback.text = "Original review"
        fixture.checkbox?.sendActions(for: .touchUpInside)
        fixture.continueButton.sendActions(for: .touchUpInside)
        fixture.continueButton.sendActions(for: .touchUpInside)
        fixture.checkbox?.sendActions(for: .touchUpInside)
        XCTAssertTrue(try XCTUnwrap(fixture.checkbox).isSelected)
        // Programmatic mutations cannot change the values already sent to the server.
        fixture.stars.rating = 5
        fixture.feedback.text = ""
        fixture.checkbox?.isSelected = false
        XCTAssertEqual(fixture.requests.count, 1)
        let request = try XCTUnwrap(fixture.requests.first)
        XCTAssertEqual(request.comment, "Original review")
        request.complete(.success(SubmitBookReviewResponse(success: true, newRating: 3, newNumberOfRatings: 1, isUpdate: false)))
        XCTAssertEqual(fixture.outcomes.map(\.name), ["bookRated", "bookRatedWithComment", "bookRatedWithAuthorShare"])
        XCTAssertEqual(fixture.outcomes.first?.parameters["rating"], "3")
    }

    func testSheetLayoutAppearanceAndKeyboard() throws {
        for variant in [BookReviewVariant.original, .originalRatingRequired, .reviewStyle] {
            for style in [UIUserInterfaceStyle.light, .dark] {
                try captureSheet(variant: variant, style: style, showsCheckbox: true)
            }
        }
        try captureSheet(variant: .original, style: .light, showsCheckbox: false)
        try captureSheet(variant: .reviewStyle, style: .light, showsCheckbox: true, largeText: true)
        for sendVariant in [BookCompletionShareButtonVariant.original, .originalWithShareIcon, .shareWithShareIcon] {
            for style in [UIUserInterfaceStyle.light, .dark] {
                try captureSheet(variant: .original, style: style, showsCheckbox: false, sendVariant: sendVariant)
            }
        }
    }

    private func captureSheet(variant: BookReviewVariant, style: UIUserInterfaceStyle, showsCheckbox: Bool, largeText: Bool = false, sendVariant: BookCompletionShareButtonVariant? = nil) throws {
        let fixture = Fixture(showsCheckbox: showsCheckbox, variant: variant, sendVariant: sendVariant ?? .original)
        let popup = fixture.popup!
        if #available(iOS 17.0, *), largeText {
            popup.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
        }
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let previousWindow = scene?.windows.first { $0.isKeyWindow }
            ?? (UIApplication.shared.delegate as? AppDelegate)?.window
        let window = scene.map(UIWindow.init(windowScene:)) ?? UIWindow(frame: UIScreen.main.bounds)
        window.frame = UIScreen.main.bounds
        window.overrideUserInterfaceStyle = style
        let root = UIViewController()
        root.view.backgroundColor = Colours.surfaceSecondary
        window.rootViewController = root
        window.windowLevel = .normal + 1
        window.makeKeyAndVisible()
        defer {
            popup.view.endEditing(true)
            popup.dismiss(animated: false)
            window.isHidden = true
            window.rootViewController = nil
            previousWindow?.makeKey()
        }
        popup.preferredSheetSizing = .fit
        let shown = expectation(description: "Sheet presented")
        root.present(popup, animated: false) { shown.fulfill() }
        wait(for: [shown], timeout: 3)
        window.layoutIfNeeded()
        if let sendVariant {
            UIView.performWithoutAnimation {
                fixture.continueButton.sendActions(for: .touchUpInside)
                window.layoutIfNeeded()
            }
            let button = fixture.sendButton
            XCTAssertEqual(button.currentTitle, sendVariant == .shareWithShareIcon ? "Share" : RCValues.shared.string(forKey: .bookCompletionShareButtonTitleAB))
            XCTAssertEqual(button.titleLabel?.font.pointSize, Fonts.semiBold16.pointSize)
            XCTAssertEqual(button.currentImage != nil, sendVariant != .original)
            XCTAssertEqual(fixture.events.filter { $0.name == "enhancedBookCompletionShareViewed" }.count, 1)
            XCTAssertTrue(fixture.requests.isEmpty)
            if sendVariant != .original {
                let imageView = try XCTUnwrap(button.imageView)
                let titleLabel = try XCTUnwrap(button.titleLabel)
                XCTAssertLessThan(imageView.frame.maxX, titleLabel.frame.minX)
                XCTAssertEqual(titleLabel.frame.minX - imageView.frame.maxX, 6, accuracy: 0.5)
                XCTAssertEqual(imageView.frame.union(titleLabel.frame).midX, button.bounds.midX, accuracy: 1)
                XCTAssertLessThanOrEqual(imageView.bounds.height, titleLabel.font.lineHeight)
                let expectedVerticalOffset: CGFloat = sendVariant == .shareWithShareIcon ? -1 : 0
                XCTAssertEqual(imageView.frame.midY, titleLabel.frame.midY + expectedVerticalOffset, accuracy: 1.5)
                XCTAssertEqual(button.tintColor, button.titleColor(for: .normal))
            }
            capture(window, name: "send-\(sendVariant.rawValue)-\(style == .dark ? "dark" : "light")")
            return
        }
        if let checkbox = fixture.checkbox {
            XCTAssertTrue(checkbox.isHidden)
            XCTAssertEqual(checkbox.bounds.height, 0, accuracy: 1)
        }
        capture(window, name: "\(variant.rawValue)-\(style == .dark ? "dark" : "light")-\(showsCheckbox ? "checkbox" : "control")\(largeText ? "-large-text" : "")")
        UIView.performWithoutAnimation {
            fixture.setRating(3)
            window.layoutIfNeeded()
        }
        XCTAssertEqual(fixture.feedback.superview?.alpha, 1)
        if let checkbox = fixture.checkbox {
            XCTAssertFalse(checkbox.isHidden)
            XCTAssertGreaterThanOrEqual(checkbox.bounds.height, 44)
            XCTAssertGreaterThan(checkbox.bounds.width, 0)
            let fieldFrame = fixture.feedback.convert(fixture.feedback.bounds, to: popup.view)
            let checkboxFrame = checkbox.convert(checkbox.bounds, to: popup.view)
            XCTAssertTrue(popup.view.bounds.contains(checkboxFrame))
            XCTAssertGreaterThanOrEqual(checkboxFrame.minY, fieldFrame.maxY)
            let imageView = try XCTUnwrap(checkbox.imageView)
            let titleLabel = try XCTUnwrap(checkbox.titleLabel)
            let groupFrame = imageView.convert(imageView.bounds, to: popup.view)
                .union(titleLabel.convert(titleLabel.bounds, to: popup.view))
            XCTAssertEqual(groupFrame.midX, fieldFrame.midX, accuracy: 1)
            checkbox.sendActions(for: .touchUpInside)
            checkbox.updateConfiguration()
            capture(window, name: "\(variant.rawValue)-\(style == .dark ? "dark" : "light")-checked-with-review\(largeText ? "-large-text" : "")")
        }

        if variant == .original && style == .light && showsCheckbox {
            let keyboardShown = expectation(for: NSPredicate { _, _ in
                popup.view.transform.ty < 0
            }, evaluatedWith: nil)
            XCTAssertTrue(fixture.feedback.becomeFirstResponder())
            wait(for: [keyboardShown], timeout: 3)
            XCTAssertLessThan(popup.view.transform.ty, 0)
            capture(window, name: "checkbox-with-keyboard")
            fixture.checkbox?.sendActions(for: .touchUpInside)
            XCTAssertTrue(fixture.feedback.isFirstResponder)
            let keyboardHidden = expectation(for: NSPredicate { _, _ in
                popup.view.transform == .identity
            }, evaluatedWith: nil)
            XCTAssertEqual(fixture.feedback.returnKeyType, .done)
            fixture.feedback.insertText("A good read.")
            let shouldInsertNewline = fixture.feedback.delegate?.textView?(
                fixture.feedback,
                shouldChangeTextIn: NSRange(location: fixture.feedback.text.utf16.count, length: 0),
                replacementText: "\n"
            )
            XCTAssertEqual(shouldInsertNewline, false)
            XCTAssertEqual(fixture.feedback.text, "A good read.")
            XCTAssertFalse(fixture.feedback.isFirstResponder)
            XCTAssertTrue(fixture.requests.isEmpty)
            wait(for: [keyboardHidden], timeout: 3)
        }
    }

    private func capture(_ window: UIWindow, name: String) {
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

@MainActor
private final class Fixture {
    struct Event {
        let name: String
        let parameters: [String: String]
    }
    struct Request {
        let rating: Double
        let type: ReviewedContentType
        let comment: String?
        let complete: (ContentRatingManager.BookReviewResult) -> Void
    }
    var events: [Event] = []
    var requests: [Request] = []
    var popup: EnhancedBookCompletionPopupVC!
    var outcomes: [Event] { events.filter { $0.name.hasPrefix("bookRated") } }
    var checkbox: UIButton? { descendants(popup.view).first { $0.accessibilityIdentifier == "bookCompletionAuthorShare" } as? UIButton }
    var continueButton: UIButton { descendants(popup.view).first { $0.accessibilityIdentifier == "bookCompletionContinue" } as! UIButton }
    var sendButton: UIButton { descendants(popup.view).first { $0.accessibilityIdentifier == "bookCompletionSend" } as! UIButton }
    var stars: CosmosView { descendants(popup.view).compactMap { $0 as? CosmosView }.first! }
    var feedback: UITextView { descendants(popup.view).compactMap { $0 as? UITextView }.first! }

    init(showsCheckbox: Bool, variant: BookReviewVariant = .original, type: ReviewedContentType = .bookInternalAudiobook, sendVariant: BookCompletionShareButtonVariant = .original) {
        let analytics = AnalyticsManager { [weak self] name, parameters in
            self?.events.append(Event(name: name, parameters: parameters as? [String: String] ?? [:]))
        }
        popup = EnhancedBookCompletionPopupVC(
            metadata: ReviewMetadata(contentType: .bookInternal),
            reviewedContentType: type,
            bookReviewVariant: variant,
            shareButtonVariant: sendVariant,
            shouldShowBookReviewAuthorShare: showsCheckbox,
            analytics: analytics,
            recordRating: { [weak self] rating, _, type, comment, completion in
                self?.requests.append(Request(rating: rating, type: type, comment: comment, complete: completion))
            }
        )
    }

    func setRating(_ rating: Double) {
        stars.rating = rating
        stars.didTouchCosmos?(rating)
    }

    private func descendants(_ view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap(descendants)
    }
}

private struct ReviewMetadata: ReadableContentMetadata {
    let contentType: ContentType
    let contentUUID = "author-share-test"
    let title: String? = "The Secret Garden"
    let coverImageXLURLString: String? = nil
    let coverImageURLString: String? = nil
    let coverImageThumbnailURLString: String? = nil
    let readerCountInt = 0
    let subtitleText = "Frances Hodgson Burnett"
    let authorsString = "Frances Hodgson Burnett"
    let genreDisplayString: String? = nil
    let tags: [String] = []
    let synopsis: String? = nil
    let needsAISynopsis = false
    let collectionsText: String? = nil
    let lengthDisplayText: String? = nil
    let hasAnyAudiobook = false
    let hasDownloadedAudio = false
    let hasDownloadedText = false
    let progressPercentageString = "100%"
    let isContentStored = false
    let sharingDeeplinkURL: String? = nil
    func getReadingOffset() -> ReadingOffset? { nil }
    func setReadingOffset(currentSection: Int, totalSections: Int, yOffset: CGFloat, totalYOffset: CGFloat) {}
    func markCompleted() {}
    func isCompleted() -> Bool { true }
}
