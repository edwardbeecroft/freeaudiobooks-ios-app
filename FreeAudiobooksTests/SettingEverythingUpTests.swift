import XCTest
import UIKit
@testable import FreeAudiobooks

final class SettingEverythingUpScheduleTests: XCTestCase {
    func testSchedulesHaveFixedDurationAndMonotonicBoundedProgress() throws {
        for seed in 0..<100 {
            let schedule = SettingEverythingUpSchedule(seed: UInt64(seed))
            XCTAssertEqual(schedule.duration, 9, accuracy: 0.000001)
            XCTAssertEqual(schedule.percent(at: 0), 0)
            XCTAssertEqual(schedule.percent(at: 8.5), 100)
            var previous = 0
            for step in schedule.steps {
                XCTAssertGreaterThan(step.delay, 0)
                XCTAssertGreaterThan(step.percent, previous)
                XCTAssertLessThanOrEqual(step.percent, 100)
                previous = step.percent
            }
            XCTAssertEqual(try XCTUnwrap(schedule.time(toReach: 20)), 1.5, accuracy: 0.000001)
            XCTAssertEqual(try XCTUnwrap(schedule.time(toReach: 91)), 6.6, accuracy: 0.000001)
            XCTAssertEqual(try XCTUnwrap(schedule.time(toReach: 95)), 8.2, accuracy: 0.000001)
        }
        XCTAssertEqual(SettingEverythingUpSchedule(seed: 7).steps, SettingEverythingUpSchedule(seed: 7).steps)
        XCTAssertNotEqual(SettingEverythingUpSchedule(seed: 7).steps, SettingEverythingUpSchedule(seed: 8).steps)
    }

    func testChecklistAndStatusMilestones() {
        XCTAssertEqual(SettingEverythingUpSchedule.completedRowCount(at: 19), 0)
        XCTAssertEqual(SettingEverythingUpSchedule.completedRowCount(at: 20), 1)
        XCTAssertEqual(SettingEverythingUpSchedule.completedRowCount(at: 50), 2)
        XCTAssertEqual(SettingEverythingUpSchedule.completedRowCount(at: 99), 3)
        XCTAssertEqual(SettingEverythingUpSchedule.completedRowCount(at: 100), 4)
        XCTAssertEqual(SettingEverythingUpSchedule.statusLine(at: 0), "Reading your answers…")
        XCTAssertEqual(SettingEverythingUpSchedule.statusLine(at: 20), "Finding your next listens…")
        XCTAssertEqual(SettingEverythingUpSchedule.statusLine(at: 50), "Building your listening routine…")
        XCTAssertEqual(SettingEverythingUpSchedule.statusLine(at: 80), "Almost ready…")
        XCTAssertEqual(SettingEverythingUpSchedule.statusLine(at: 100), "Ready!")
    }

    func testPlaybackWaitsForFinalHoldAndCompletesExactlyOnce() {
        var playback = SettingEverythingUpPlayback(schedule: SettingEverythingUpSchedule(seed: 1))
        XCTAssertFalse(playback.tick(at: 50)) // Never started.
        playback.resume(at: 100)
        XCTAssertFalse(playback.tick(at: 108.5))
        XCTAssertEqual(playback.percent, 100)
        XCTAssertFalse(playback.tick(at: 108.99))
        XCTAssertTrue(playback.tick(at: 109.01))
        XCTAssertFalse(playback.tick(at: 110))
        playback.resume(at: 200)
        XCTAssertFalse(playback.tick(at: 210))
    }

    func testBackgroundTimeDoesNotAdvancePlaybackIncludingFinalHold() {
        var playback = SettingEverythingUpPlayback(schedule: SettingEverythingUpSchedule(seed: 1))
        playback.resume(at: 0)
        playback.resume(at: 1) // Duplicate appearance must not restart the clock.
        playback.pause(at: 3)
        let pausedPercent = playback.percent
        XCTAssertFalse(playback.tick(at: 100))
        XCTAssertEqual(playback.percent, pausedPercent)
        playback.resume(at: 100)
        XCTAssertFalse(playback.tick(at: 105.5))
        XCTAssertEqual(playback.percent, 100)
        playback.pause(at: 105.6)
        playback.resume(at: 200)
        XCTAssertFalse(playback.tick(at: 200.39))
        XCTAssertTrue(playback.tick(at: 200.41))
    }

    func testCancellationCannotResumeOrComplete() {
        var playback = SettingEverythingUpPlayback(schedule: SettingEverythingUpSchedule(seed: 1))
        playback.resume(at: 0)
        XCTAssertFalse(playback.tick(at: 2))
        playback.cancel()
        let percent = playback.percent
        playback.resume(at: 20)
        XCTAssertFalse(playback.tick(at: 100))
        XCTAssertEqual(playback.percent, percent)
        XCTAssertFalse(playback.didComplete)
    }
}

@MainActor
final class SettingEverythingUpFlowTests: XCTestCase {
    private var savedDefaults: [String: Any] = [:]

    override func setUp() {
        super.setUp()
        savedDefaults = onboardingDefaults()
        onboardingDefaults().keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    override func tearDown() {
        onboardingDefaults().keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        savedDefaults.forEach { UserDefaults.standard.set($0.value, forKey: $0.key) }
        super.tearDown()
    }

    private func onboardingDefaults() -> [String: Any] {
        UserDefaults.standard.dictionaryRepresentation().filter { $0.key.hasPrefix("newOnboarding_") }
    }

    func testTreatmentsOnlyAddSetupAtTheirDestinationWithIdenticalProgress() throws {
        let control = OnboardingVariant.fullFlowAuthFirst.steps
        XCTAssertTrue(control.contains(.credibilityReviews))
        XCTAssertFalse(control.contains(.settingEverythingUp))
        for (variant, destination) in [(OnboardingVariant.setupBeforePersonalizedPicks, NewOnboardingStep.personalizedPicks), (.setupBeforePaywall, .paywall)] {
            let steps = variant.steps
            let index = try XCTUnwrap(steps.firstIndex(of: .settingEverythingUp))
            XCTAssertEqual(steps[index + 1], destination)
            XCTAssertTrue(steps.contains(.credibilityReviews))
            XCTAssertEqual(steps.filter { $0 != .settingEverythingUp }, control)
            XCTAssertEqual(steps.filter(\.includesInProgressBar), control.filter(\.includesInProgressBar))
        }
    }

    func testFreeAudiobooksControlPreservesAuthFirstAndListeningSteps() throws {
        let control = OnboardingVariant.fullFlowAuthFirst.steps
        XCTAssertTrue(control.contains(.listeningOccasion))
        XCTAssertTrue(control.contains(.whyDoYouListen))
        XCTAssertTrue(control.contains(.dailyListeningGoal))
        XCTAssertFalse(control.contains(.readingFrequency))
        XCTAssertLessThan(try XCTUnwrap(control.firstIndex(of: .saveProgressAuth)),
                          try XCTUnwrap(control.firstIndex(of: .paywall)))
        let legacy = OnboardingVariant.fullFlow.steps
        XCTAssertLessThan(try XCTUnwrap(legacy.firstIndex(of: .paywall)),
                          try XCTUnwrap(legacy.firstIndex(of: .saveProgressAuth)))
        XCTAssertEqual(RCKeys.onboardingVariantv3AB.rawValue, "onboardingVariantv3AB")
        XCTAssertEqual(NewOnboardingCoordinator.resolveVariant(persistedValue: "fullFlowAuthFirst", currentVariant: .setupBeforePaywall), .fullFlowAuthFirst)
    }

    func testSubscriberFilteringAndLegacyVariants() {
        let early = makeCoordinator(.setupBeforePersonalizedPicks, isSubscribed: true).steps
        let late = makeCoordinator(.setupBeforePaywall, isSubscribed: true).steps
        XCTAssertTrue(early.contains(.settingEverythingUp))
        XCTAssertFalse(early.contains(.paywall))
        XCTAssertFalse(late.contains(.settingEverythingUp))
        XCTAssertFalse(late.contains(.paywall))
        for variant in [OnboardingVariant.fullFlowAuthFirst, .noPersonalizedPicks, .noPaywall, .mini, .welcomeAndGenre, .genreOnly] {
            XCTAssertFalse(variant.steps.contains(.settingEverythingUp))
        }
    }

    func testAssignmentPrecedenceAndInvalidSavedValueFallback() {
        XCTAssertEqual(NewOnboardingCoordinator.resolveVariant(persistedValue: "setupBeforePersonalizedPicks", currentVariant: .setupBeforePaywall), .setupBeforePersonalizedPicks)
        XCTAssertEqual(NewOnboardingCoordinator.resolveVariant(persistedValue: "unknown", currentVariant: .setupBeforePaywall), .setupBeforePaywall)
        XCTAssertEqual(NewOnboardingCoordinator.resolveVariant(persistedValue: nil, currentVariant: .setupBeforePersonalizedPicks), .setupBeforePersonalizedPicks)
        XCTAssertEqual(NewOnboardingCoordinator.resolveVariant(persistedValue: "unknown", currentVariant: .fullFlow), .fullFlow)
    }

    func testResolvedAssignmentIsSavedImmediatelyAndCannotBeOverwrittenByRestore() {
        NewOnboardingUserDefaults.saveOnboardingVariant("fullFlow")
        let coordinator = makeCoordinator(.setupBeforePaywall)
        XCTAssertEqual(coordinator.dataStore.variant, .setupBeforePaywall)
        XCTAssertEqual(NewOnboardingUserDefaults.getOnboardingVariant(), "setupBeforePaywall")
        let resumedVariant = NewOnboardingCoordinator.resolveVariant(persistedValue: NewOnboardingUserDefaults.getOnboardingVariant(), currentVariant: .fullFlow)
        let resumed = makeCoordinator(resumedVariant)
        advance(resumed, to: .settingEverythingUp)
        XCTAssertEqual(resumed.dataStore.variant, .setupBeforePaywall)
        resumed.goToNextScreen()
        XCTAssertEqual(resumed.currentStep, .paywall)
    }

    func testBackSkipsSetupAndForwardReplaysItWithoutChangingProgress() {
        let coordinator = makeCoordinator(.setupBeforePersonalizedPicks)
        advance(coordinator, to: .credibilityReviews)
        let previousProgress = coordinator.currentProgress
        coordinator.goToNextScreen()
        XCTAssertEqual(coordinator.currentStep, .settingEverythingUp)
        XCTAssertEqual(coordinator.currentProgress, previousProgress)
        coordinator.goToNextScreen()
        XCTAssertEqual(coordinator.currentStep, .personalizedPicks)
        coordinator.goToPreviousScreen()
        XCTAssertEqual(coordinator.currentStep, .credibilityReviews)
        coordinator.goToNextScreen()
        XCTAssertEqual(coordinator.currentStep, .settingEverythingUp)
    }

    func testAuthSkipStillVisitsLateSetupAndSetupDoesNotBlockResume() {
        let coordinator = makeCoordinator(.setupBeforePaywall)
        advance(coordinator, to: .personalizedPicks)
        coordinator.dataStore.authMethod = "apple"
        coordinator.goToNextScreen()
        XCTAssertEqual(coordinator.currentStep, .settingEverythingUp)
        coordinator.goToNextScreen()
        XCTAssertEqual(coordinator.currentStep, .paywall)
        XCTAssertTrue(NewOnboardingStep.settingEverythingUp.isComplete(dataStore: NewOnboardingDataStore()))
    }

    func testStaleScreenCannotAdvanceCurrentJourney() {
        let coordinator = makeCoordinator(.setupBeforePaywall)
        advance(coordinator, to: .settingEverythingUp)
        let stale = SettingEverythingUpVC(coordinator: coordinator)
        XCTAssertFalse(coordinator.completeSetupScreen(stale))
        XCTAssertEqual(coordinator.currentStep, .settingEverythingUp)
    }

    func testVisibleScreenPausesAndAutomaticallyAdvancesExactlyOnce() throws {
        let coordinator = makeCoordinator(.setupBeforePersonalizedPicks)
        advance(coordinator, to: .settingEverythingUp)
        let container = coordinator.createContainerVC()
        let previousWindow = (UIApplication.shared.delegate as? AppDelegate)?.window
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = container
        window.windowLevel = .alert + 1
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
            previousWindow?.makeKey()
        }
        container.loadViewIfNeeded()
        container.transitionToStep(.settingEverythingUp, direction: .none)
        let screen = try XCTUnwrap(container.children.first as? SettingEverythingUpVC)
        let paused = expectation(description: "Visible animation pauses during inactivity")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
            let percent = screen.percent
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                XCTAssertEqual(screen.percent, percent)
                XCTAssertEqual(coordinator.currentStep, .settingEverythingUp)
                NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
                paused.fulfill()
            }
        }
        let advanced = expectation(for: NSPredicate { _, _ in
            coordinator.currentStep == .personalizedPicks
        }, evaluatedWith: nil)
        wait(for: [paused, advanced], timeout: 12)
        XCTAssertEqual(screen.percent, 100)
        XCTAssertTrue(screen.didAdvance)
        XCTAssertFalse(coordinator.completeSetupScreen(screen))
        XCTAssertEqual(coordinator.currentStep, .personalizedPicks)
    }

    func testSetupScreenLayoutAndChecklistInBothPlacements() throws {
        print("Setup-screen Reduce Motion: \(UIAccessibility.isReduceMotionEnabled)")
        for variant in [OnboardingVariant.setupBeforePersonalizedPicks, .setupBeforePaywall] {
            for style in [UIUserInterfaceStyle.light, .dark] {
                try captureScreen(variant: variant, style: style, largeText: false)
            }
        }
        try captureScreen(variant: .setupBeforePersonalizedPicks, style: .light, largeText: true)
    }

    private func captureScreen(variant: OnboardingVariant, style: UIUserInterfaceStyle, largeText: Bool) throws {
        let coordinator = makeCoordinator(variant)
        advance(coordinator, to: .settingEverythingUp)
        let container = coordinator.createContainerVC()
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let previousWindow = scene?.windows.first { $0.isKeyWindow }
            ?? (UIApplication.shared.delegate as? AppDelegate)?.window
        let window = scene.map(UIWindow.init(windowScene:)) ?? UIWindow(frame: UIScreen.main.bounds)
        window.frame = UIScreen.main.bounds
        window.overrideUserInterfaceStyle = style
        window.rootViewController = container
        window.windowLevel = .alert + 1
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
            previousWindow?.makeKey()
        }
        container.loadViewIfNeeded()
        container.transitionToStep(.settingEverythingUp, direction: .none)
        let screen = try XCTUnwrap(container.children.first as? SettingEverythingUpVC)
        if largeText {
            container.setOverrideTraitCollection(UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge), forChild: screen)
        }
        UIView.performWithoutAnimation {
            window.layoutIfNeeded()
            screen.apply(percent: 93)
            window.layoutIfNeeded()
        }
        XCTAssertFalse(screen.showsContinueButton)
        XCTAssertFalse(screen.showsProgressBar)
        XCTAssertFalse(screen.showsBackButton)
        let descendants = allSubviews(screen.view)
        XCTAssertEqual(descendants.filter { $0.accessibilityValue == "Done" }.count, 3)
        let labels = descendants.compactMap { $0 as? UILabel }
        for text in SettingEverythingUpSchedule.checklist {
            let label = try XCTUnwrap(labels.first { $0.text == text })
            XCTAssertGreaterThanOrEqual(label.bounds.height, label.font.lineHeight - 1)
            XCTAssertEqual(label.font.pointSize, Fonts.regular17.pointSize)
            XCTAssertFalse(label.adjustsFontForContentSizeCategory)
        }
        let scroll = try XCTUnwrap(descendants.compactMap { $0 as? UIScrollView }.first)
        XCTAssertGreaterThan(scroll.bounds.width, 0)
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = "\(variant.rawValue)-\(style == .dark ? "dark" : "light")\(largeText ? "-large-text" : "")"
        attachment.lifetime = .keepAlways
        add(attachment)
        UIView.performWithoutAnimation { screen.apply(percent: 100) }
        XCTAssertEqual(descendants.filter { $0.accessibilityValue == "Done" }.count, 4)

    }

    private func allSubviews(_ view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap(allSubviews)
    }

    private func makeCoordinator(_ variant: OnboardingVariant, isSubscribed: Bool = false) -> NewOnboardingCoordinator {
        let coordinator = NewOnboardingCoordinator()
        coordinator.configureFlow(variant: variant, isSubscribed: isSubscribed)
        return coordinator
    }

    private func advance(_ coordinator: NewOnboardingCoordinator, to step: NewOnboardingStep) {
        for _ in 0..<20 {
            if coordinator.currentStep == step { return }
            if coordinator.currentStep == .paywall { break }
            coordinator.goToNextScreen()
        }
        XCTFail("Could not reach \(step) from \(String(describing: coordinator.currentStep))")
    }
}
