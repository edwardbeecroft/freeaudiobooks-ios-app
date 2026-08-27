//
//  StatsVC.swift
//  FreeAudiobooks
//
//  Created by FreeAudiobooks on 15/11/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

private enum StatsSummaryPeriod {
    case allTime
    case thisWeek
}

class StatsVC: UIViewController {

    private enum MomentumState {
        case notStarted
        case inProgress(minutesRead: Int, minutesRemaining: Int)
        case completed
        case freezeSaved
        case streakLost
    }

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let heroCardView = StatsMomentumHeroCardView()
    private let todayCardView = StatsTodayProgressCardView()
    private let allTimeCardView = StatsAllTimeSummaryCardView()

    private var percentiles: UserPercentiles?
    private var currentViewModel: StatsMomentumViewModel?
    private var selectedStatsPeriod: StatsSummaryPeriod = .allTime
    private var hasTriggeredCompletionHaptic = false
    private var hasPlayedEntranceAnimations = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.dynamic(light: .white, dark: .black)

        setupNavigationBar()
        setupScrollView()
        setupContent()
        bindActions()
        render()
        fetchPercentiles()

        AnalyticsManager.shared.trackViewedStatsPage()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard NavigationBarStyler.reapplyIfNeeded(on: self, previousTraitCollection: previousTraitCollection) else { return }
        setupNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !hasPlayedEntranceAnimations else { return }
        hasPlayedEntranceAnimations = true

        heroCardView.animateMetricOnAppearIfNeeded()
        todayCardView.animateProgressOnAppearIfNeeded()

        if currentViewModel?.today.progress ?? 0 >= 1, !hasTriggeredCompletionHaptic {
            hasTriggeredCompletionHaptic = true
            HapticFeedbackHelper.shared.triggerLightImpactFeedback()
        }
    }

    private func setupNavigationBar() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        navigationBar.tintColor = Colours.textPrimary
        navigationBar.barTintColor = Colours.chromeBackground

        let closeButton = UIButton(type: .system)
        let closeImage = UIImage(named: "dismissIcon")?.withRenderingMode(.alwaysTemplate)
        closeButton.setImage(closeImage, for: .normal)
        closeButton.tintColor = Colours.textPrimary
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: closeButton)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Colours.chromeBackground
        appearance.titleTextAttributes = Fonts.navBarTitleTextAttributes
        appearance.shadowImage = nil
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance

        title = "Your Listening Stats"
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    private func setupScrollView() {
        view.addSubviewForConstraints(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        scrollView.addSubviewForConstraints(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: UIConstants.shared.standardMargin),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -UIConstants.shared.standardMargin),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -28),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -2 * UIConstants.shared.standardMargin)
        ])

        contentStack.axis = .vertical
        contentStack.spacing = 18
        contentStack.alignment = .fill
    }

    private func setupContent() {
        [heroCardView, todayCardView, allTimeCardView].forEach {
            contentStack.addArrangedSubview($0)
        }
    }

    private func bindActions() {
        heroCardView.primaryActionTapped = { [weak self] in
            self?.handlePrimaryCTA()
        }
        todayCardView.editTapped = { [weak self] sourceView in
            self?.presentGoalEditor(from: sourceView)
        }
        allTimeCardView.periodChanged = { [weak self] period in
            HapticFeedbackHelper.shared.triggerLightImpactFeedback()
            self?.selectedStatsPeriod = period
            self?.render()
        }
    }

    private func fetchPercentiles() {
        PercentileService.shared.fetchUserPercentiles { [weak self] percentiles in
            guard let self else { return }

            DispatchQueue.main.async {
                self.percentiles = percentiles
                self.render()
            }
        }
    }

    private func render() {
        guard let user = AccountManager.shared.user else { return }

        let viewModel = makeViewModel(for: user, percentiles: percentiles)
        currentViewModel = viewModel

        heroCardView.configure(with: viewModel.hero)
        todayCardView.configure(with: viewModel.today)
        allTimeCardView.configure(with: viewModel.allTime)
    }

    private func makeViewModel(for user: User, percentiles: UserPercentiles?) -> StatsMomentumViewModel {
        let dailyGoalMinutes = NewOnboardingUserDefaults.getDailyListeningGoal() ?? 15
        let todayReadingSeconds = SessionTrackingManager.todayReadingSeconds()
        let dailyGoalSeconds = dailyGoalMinutes * 60
        let totalBooks = user.completedBookInternalUUIDs.count + user.completedStoryUUIDs.count
        let inProgressContent = ReadingUserDefaults.getReadingInProgressContent()
        let continueMetadata = inProgressContent.first
        let momentumState = makeMomentumState(
            user: user,
            todayReadingSeconds: todayReadingSeconds,
            dailyGoalSeconds: dailyGoalSeconds
        )
        let heroMetricText: String
        let heroMessage: String
        let heroSecondary: String?
        let buttonTitle: String
        let todayValueText: String
        let todayMessage: String
        let showsStreakIcon: Bool

        switch momentumState {
        case .notStarted:
            heroMetricText = "\(user.currentStreak) \(user.currentStreak == 1 ? "day" : "days")"
            heroMessage = "Keep your streak going today"
            heroSecondary = "Longest: \(user.longestStreak) \(user.longestStreak == 1 ? "day" : "days")"
            todayValueText = "0 / \(dailyGoalMinutes) min"
            todayMessage = "Start with a few minutes"
            showsStreakIcon = true
        case let .inProgress(minutesRead, minutesRemaining):
            heroMetricText = "\(user.currentStreak) \(user.currentStreak == 1 ? "day" : "days")"
            heroMessage = "Keep going — you're building momentum"
            heroSecondary = "Longest: \(user.longestStreak) \(user.longestStreak == 1 ? "day" : "days")"
            todayValueText = "\(minutesRead) / \(dailyGoalMinutes) min"
            todayMessage = "\(minutesRemaining) min to reach today’s goal"
            showsStreakIcon = true
        case .completed:
            heroMetricText = "\(user.currentStreak) \(user.currentStreak == 1 ? "day" : "days")"
            heroMessage = "You're on fire — keep the momentum going"
            heroSecondary = "Longest: \(user.longestStreak) \(user.longestStreak == 1 ? "day" : "days")"
            todayValueText = "\(dailyGoalMinutes) / \(dailyGoalMinutes) min ✓"
            todayMessage = "Nice work — you showed up today"
            showsStreakIcon = true
        case .freezeSaved:
            heroMetricText = "Streak saved"
            heroMessage = "Your freeze kept the streak alive"
            heroSecondary = "Longest: \(user.longestStreak) \(user.longestStreak == 1 ? "day" : "days")"
            todayValueText = "0 / \(dailyGoalMinutes) min"
            todayMessage = "Start again today"
            showsStreakIcon = false
        case .streakLost:
            heroMetricText = "Start fresh"
            heroMessage = "Listen today to begin a new streak"
            heroSecondary = nil
            todayValueText = "0 / \(dailyGoalMinutes) min"
            todayMessage = "A few minutes is all it takes"
            showsStreakIcon = false
        }
        buttonTitle = makeButtonTitle(for: momentumState, inProgressCount: inProgressContent.count)
        let totalReadingTimeText: String
        let totalBooksText: String
        let readingTimePercentile: Int?
        let booksBadgeState: PercentileBadgeState?
        let completedBooksInSelectedPeriod: Int

        switch selectedStatsPeriod {
        case .allTime:
            totalReadingTimeText = SessionTrackingManager.formatReadingTime(seconds: user.totalReadingTimeSeconds)
            totalBooksText = "\(totalBooks) books"
            readingTimePercentile = percentiles?.totalTimePercentile
            completedBooksInSelectedPeriod = totalBooks
            booksBadgeState = makeBooksBadgeState(
                percentile: percentiles?.totalBooksPercentile,
                completedBooksCount: completedBooksInSelectedPeriod,
                inProgressCount: inProgressContent.count
            )
        case .thisWeek:
            totalReadingTimeText = SessionTrackingManager.formatReadingTime(seconds: user.weeklyReadingTimeSeconds)
            totalBooksText = "\(user.weeklyBooksReadCount) books"
            readingTimePercentile = percentiles?.weeklyTimePercentile
            completedBooksInSelectedPeriod = user.weeklyBooksReadCount
            booksBadgeState = makeBooksBadgeState(
                percentile: percentiles?.weeklyBooksPercentile,
                completedBooksCount: completedBooksInSelectedPeriod,
                inProgressCount: inProgressContent.count
            )
        }

        return StatsMomentumViewModel(
            hero: .init(
                title: nil,
                metricText: heroMetricText,
                message: heroMessage,
                secondary: heroSecondary,
                buttonTitle: buttonTitle,
                showsStreakIcon: showsStreakIcon
            ),
            today: .init(
                title: "TODAY",
                valueText: todayValueText,
                message: todayMessage,
                progress: dailyGoalSeconds > 0 ? min(Float(todayReadingSeconds) / Float(dailyGoalSeconds), 1) : 0
            ),
            allTime: .init(
                selectedPeriod: selectedStatsPeriod,
                readingTimeLine: totalReadingTimeText,
                booksLine: totalBooksText,
                readingTimePercentile: readingTimePercentile,
                booksBadgeState: booksBadgeState
            ),
            continueMetadata: continueMetadata
        )
    }

    private func makeButtonTitle(for momentumState: MomentumState, inProgressCount: Int) -> String {
        switch inProgressCount {
        case 0:
            return "Listen Now"
        case 1:
            return "Continue Listening"
        default:
            return "Continue Listening"
        }
    }

    private func makeBooksBadgeState(
        percentile: Int?,
        completedBooksCount: Int,
        inProgressCount: Int
    ) -> PercentileBadgeState? {
        if let percentile {
            return .percentile(percentile)
        }

        if completedBooksCount > 0 {
            return nil
        }

        if completedBooksCount == 0 {
            return inProgressCount > 0 ? .inProgress : .gettingStarted
        }

        return nil
    }

    private func makeMomentumState(user: User, todayReadingSeconds: Int, dailyGoalSeconds: Int) -> MomentumState {
        if dailyGoalSeconds > 0, todayReadingSeconds >= dailyGoalSeconds {
            return .completed
        }

        if todayReadingSeconds > 0 {
            let goalMinutes = max(dailyGoalSeconds / 60, 1)
            let minutesRead = min(max(1, Int(ceil(Double(todayReadingSeconds) / 60.0))), goalMinutes)
            let remainingMinutes = max(goalMinutes - minutesRead, 0)
            return .inProgress(minutesRead: min(minutesRead, goalMinutes), minutesRemaining: remainingMinutes)
        }

        if let daysSinceLastReading = SessionTrackingManager.daysSinceLastReadingActivity(),
           daysSinceLastReading > 1 {
            return user.streakFreezeUsed ? .freezeSaved : .streakLost
        }

        return .notStarted
    }

    private func presentGoalEditor(from sourceView: UIView) {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()

        let actionSheet = UIAlertController(title: "Daily Listening Goal", message: nil, preferredStyle: .actionSheet)
        let goalOptions = [10, 20, 30, 60]
        let currentGoal = NewOnboardingUserDefaults.getDailyListeningGoal() ?? 15

        for goal in goalOptions {
            let title = goal == 60 ? "60+ minutes" : "\(goal) minutes"
            let isCurrent = goal == currentGoal
            let displayTitle = isCurrent ? "\(title) ✓" : title

            actionSheet.addAction(UIAlertAction(title: displayTitle, style: .default) { [weak self] _ in
                self?.updateDailyListeningGoal(goal)
            })
        }

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }

        present(actionSheet, animated: true)
    }

    private func updateDailyListeningGoal(_ goalMinutes: Int) {
        NewOnboardingUserDefaults.saveDailyListeningGoal(goalMinutes)

        if let user = AccountManager.shared.user {
            let data: [String: Any] = [
                FirebaseUserVariables.dailyListeningGoal.rawValue: goalMinutes
            ]
            AccountManager.shared.updateUserWithData(data) { _ in }
        }

        if let reminderTimeString = NewOnboardingUserDefaults.getSelectedReminderTime(),
           let reminderTime = ReminderTime(rawValue: reminderTimeString) {
            DailyReminderScheduler.hasDailyReminderScheduled { hasReminder in
                guard hasReminder else { return }

                let customTime = NewOnboardingUserDefaults.getCustomReminderTime()
                DailyReminderScheduler.updateReminderTime(
                    reminderTime,
                    goalMinutes: goalMinutes,
                    customHour: customTime?.hour,
                    customMinute: customTime?.minute
                )
                OnboardingRetentionScheduler.refreshRemainingNudges()
            }
        }

        render()
    }

    private func handlePrimaryCTA() {
        let continueMetadata = currentViewModel?.continueMetadata

        dismiss(animated: true) { [weak self] in
            guard let self else { return }

            if let continueMetadata {
                self.routeToContinueReading(continueMetadata)
            } else {
                self.showDiscoverHome()
            }
        }
    }

    private func showDiscoverHome() {
        guard let tabBarController = appTabBarController else { return }
        tabBarController.selectTab(tab: .discover)
        discoverNavigationController?.popToRootViewController(animated: false)
    }

    private func routeToContinueReading(_ metadata: ReadableContentMetadata) {
        guard let tabBarController = appTabBarController,
              let discoverNav = discoverNavigationController,
              let homeVC = discoverNav.viewControllers.first as? HomeVC else {
            routeToBookDetail(metadata)
            return
        }

        tabBarController.selectTab(tab: .discover)
        discoverNav.popToRootViewController(animated: false)

        if ReadingUserDefaults.getLastReadMode(for: metadata.contentUUID) == .audio {
            if let bookInternal = metadata as? CDBookInternal,
               resumeCachedAudiobookIfAllowed(
                   bookInternal: bookInternal,
                   navigationController: discoverNav
               ) {
                return
            } else if let bookInternal = metadata as? CDBookInternal, !bookInternal.isAvailableToUser {
                homeVC.displayPaywall(placement: .earlyAccess, bookInternal: bookInternal)
            } else {
                routeToBookDetail(metadata)
            }
            return
        }

        let localContent: ReadableContent? = APIBookInternalContentManager.getBookInternalContent(bookUUID: metadata.contentUUID)

        if let localContent {
            presentReadingModePaywall(bookInternal: metadata as? CDBookInternal) { [weak self] in
                guard self != nil else { return }
                let bookDetailVC = BookDetailVC(contentMetadata: metadata)
                bookDetailVC.hidesBottomBarWhenPushed = true
                let readingVC = ReadingVC(metadata: metadata, content: localContent)
                readingVC.hidesBottomBarWhenPushed = true
                discoverNav.setViewControllers([homeVC, bookDetailVC, readingVC], animated: true)
            }
        } else if let bookInternal = metadata as? CDBookInternal, !bookInternal.isAvailableToUser {
            homeVC.displayPaywall(placement: .earlyAccess, bookInternal: bookInternal)
        } else {
            routeToBookDetail(metadata)
        }
    }

    private func routeToBookDetail(_ metadata: ReadableContentMetadata) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.showBook(metadata)
    }

    private var appTabBarController: AppTabBarController? {
        if let presentingNav = navigationController?.presentingViewController as? UINavigationController {
            return presentingNav.topViewController?.tabBarController as? AppTabBarController
        }

        if let accountVC = navigationController?.presentingViewController {
            return accountVC.tabBarController as? AppTabBarController
        }

        return tabBarController as? AppTabBarController
    }

    private var discoverNavigationController: UINavigationController? {
        return appTabBarController?.viewControllers?
            .first(where: { ($0 as? UINavigationController)?.viewControllers.first is HomeVC }) as? UINavigationController
    }
}

private struct StatsMomentumViewModel {
    struct Hero {
        let title: String?
        let metricText: String
        let message: String
        let secondary: String?
        let buttonTitle: String
        let showsStreakIcon: Bool
    }

    struct Today {
        let title: String
        let valueText: String
        let message: String
        let progress: Float
    }

    struct AllTime {
        let selectedPeriod: StatsSummaryPeriod
        let readingTimeLine: String
        let booksLine: String
        let readingTimePercentile: Int?
        let booksBadgeState: PercentileBadgeState?
    }

    let hero: Hero
    let today: Today
    let allTime: AllTime
    let continueMetadata: ReadableContentMetadata?
}

private final class StatsMomentumCardContainerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        configureAppearance()
    }

    private func configureAppearance() {
        backgroundColor = Colours.surfaceCard
        layer.cornerRadius = UIConstants.shared.cardCornerRadius
        layer.masksToBounds = true
    }
}

private final class StatsMomentumHeroCardView: UIView {
    private let containerView = StatsMomentumCardContainerView()
    private let sectionLabel = UILabel()
    private let streakIconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let secondaryLabel = UILabel()
    private let primaryButton = Buttons.primaryCTA(buttonTitle: "Continue Listening")
    private var targetMetricText: String?
    private var targetMetricCount: Int?
    private var metricSuffix: String = ""
    private var hasAnimatedMetric = false

    var primaryActionTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubviewForConstraints(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let accentView = UIView()
        accentView.backgroundColor = Colours.orangePrimary.withAlphaComponent(0.08)
        containerView.addSubviewForConstraints(accentView)
        NSLayoutConstraint.activate([
            accentView.topAnchor.constraint(equalTo: containerView.topAnchor),
            accentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            accentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            accentView.heightAnchor.constraint(equalToConstant: 6)
        ])

        sectionLabel.font = Fonts.semiBold13
        sectionLabel.textColor = Colours.textSecondary

        streakIconImageView.image = UIImage(named: "streak")
        streakIconImageView.contentMode = .scaleAspectFit
        streakIconImageView.tintColor = nil
        streakIconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        streakIconImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        streakIconImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true

        titleLabel.font = Fonts.semiBold25
        titleLabel.textColor = Colours.textPrimary
        titleLabel.numberOfLines = 0

        messageLabel.font = Fonts.medium16
        messageLabel.textColor = Colours.textPrimary
        messageLabel.numberOfLines = 0

        secondaryLabel.font = Fonts.regular14
        secondaryLabel.textColor = Colours.textSecondary
        secondaryLabel.numberOfLines = 0

        primaryButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight).isActive = true
        primaryButton.layer.cornerRadius = UIConstants.shared.fullButtonCornerRadius
        primaryButton.layer.masksToBounds = true
        primaryButton.addTarget(self, action: #selector(primaryButtonTapped), for: .touchUpInside)

        let metricStack = UIStackView(arrangedSubviews: [streakIconImageView, titleLabel])
        metricStack.axis = .horizontal
        metricStack.spacing = 8
        metricStack.alignment = .center

        let stack = UIStackView(arrangedSubviews: [sectionLabel, metricStack, messageLabel, secondaryLabel, primaryButton])
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .fill

        containerView.addSubviewForConstraints(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 22),
            stack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }

    func configure(with viewModel: StatsMomentumViewModel.Hero) {
        sectionLabel.text = viewModel.title
        sectionLabel.isHidden = viewModel.title == nil
        targetMetricText = viewModel.metricText
        targetMetricCount = parseMetricCount(from: viewModel.metricText)
        metricSuffix = parseMetricSuffix(from: viewModel.metricText)

        if !hasAnimatedMetric,
           viewModel.showsStreakIcon,
           let targetMetricCount {
            let startValue = max(targetMetricCount - 2, Int(floor(Double(targetMetricCount) * 0.85)))
            titleLabel.text = "\(startValue)\(metricSuffix)"
        } else {
            titleLabel.text = viewModel.metricText
        }

        streakIconImageView.isHidden = !viewModel.showsStreakIcon
        messageLabel.text = viewModel.message
        secondaryLabel.text = viewModel.secondary
        secondaryLabel.isHidden = viewModel.secondary == nil
        primaryButton.setTitle(viewModel.buttonTitle, for: .normal)
    }

    func animateMetricOnAppearIfNeeded() {
        guard !hasAnimatedMetric,
              !streakIconImageView.isHidden,
              let targetMetricCount,
              let targetMetricText else { return }

        hasAnimatedMetric = true
        let startValue = max(targetMetricCount - 2, Int(floor(Double(targetMetricCount) * 0.85)))
        titleLabel.text = "\(startValue)\(metricSuffix)"
        titleLabel.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        UIView.animate(withDuration: 0.38,
                       delay: 0,
                       options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState]) {
            self.titleLabel.transform = .identity
        }

        let duration: TimeInterval = 0.4
        let startTime = CACurrentMediaTime()

        let displayLink = CADisplayLink(target: DisplayLinkProxy(callback: { [weak self] link in
            guard let self else {
                link.invalidate()
                return
            }

            let elapsed = CACurrentMediaTime() - startTime
            let progress = min(elapsed / duration, 1)
            let easedProgress = 1 - pow(1 - progress, 3)
            let interpolatedValue = Double(startValue) + (Double(targetMetricCount - startValue) * easedProgress)
            let currentValue = Int(round(interpolatedValue))
            self.titleLabel.text = "\(currentValue)\(self.metricSuffix)"

            if progress >= 1 {
                self.titleLabel.text = targetMetricText
                link.invalidate()
            }
        }), selector: #selector(DisplayLinkProxy.handleDisplayLink(_:)))
        displayLink.add(to: .main, forMode: .common)
    }

    @objc private func primaryButtonTapped() {
        primaryActionTapped?()
    }

    private func parseMetricCount(from text: String) -> Int? {
        let digits = text.prefix { $0.isNumber }
        return Int(digits)
    }

    private func parseMetricSuffix(from text: String) -> String {
        let digits = text.prefix { $0.isNumber }
        return String(text.dropFirst(digits.count))
    }
}

private final class StatsTodayProgressCardView: UIView {
    private let containerView = StatsMomentumCardContainerView()
    private let titleLabel = UILabel()
    private let editButton = UIButton(type: .system)
    private let valueLabel = UILabel()
    private let messageLabel = UILabel()
    private let progressView = RoundedProgressView()
    private var targetProgress: Float = 0
    private var hasAnimatedProgress = false

    var editTapped: ((UIView) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubviewForConstraints(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        titleLabel.font = Fonts.semiBold13
        titleLabel.textColor = Colours.textSecondary

        editButton.setTitle("Edit", for: .normal)
        editButton.setTitleColor(Colours.textSecondary, for: .normal)
        editButton.titleLabel?.font = Fonts.medium12
        editButton.addTarget(self, action: #selector(handleEditTapped), for: .touchUpInside)
        
        // Don't show this for now
        editButton.isHidden = true
        
        valueLabel.font = Fonts.semiBold25
        valueLabel.textColor = Colours.textPrimary

        messageLabel.font = Fonts.regular15
        messageLabel.textColor = Colours.textSecondary
        messageLabel.numberOfLines = 0

        progressView.trackTintColor = Colours.separator
        progressView.progressTintColor = Colours.orangePrimary
        progressView.heightAnchor.constraint(equalToConstant: 8).isActive = true

        let headerRow = UIStackView(arrangedSubviews: [titleLabel, UIView(), editButton])
        headerRow.axis = .horizontal
        headerRow.spacing = 10
        headerRow.alignment = .center

        let stack = UIStackView(arrangedSubviews: [headerRow, valueLabel, progressView, messageLabel])
        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .fill

        containerView.addSubviewForConstraints(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }

    func configure(with viewModel: StatsMomentumViewModel.Today) {
        titleLabel.text = viewModel.title
        valueLabel.text = viewModel.valueText
        messageLabel.text = viewModel.message
        messageLabel.isHidden = false
        targetProgress = min(max(viewModel.progress, 0), 1)

        if hasAnimatedProgress {
            progressView.setProgress(targetProgress, animated: true)
        } else {
            progressView.progress = 0
        }
    }

    @objc private func handleEditTapped() {
        editTapped?(editButton)
    }

    func animateProgressOnAppearIfNeeded() {
        guard !hasAnimatedProgress else { return }
        hasAnimatedProgress = true
        UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseOut) {
            self.progressView.setProgress(self.targetProgress, animated: false)
            self.progressView.layoutIfNeeded()
        }
    }
}

private final class DisplayLinkProxy: NSObject {
    private let callback: (CADisplayLink) -> Void

    init(callback: @escaping (CADisplayLink) -> Void) {
        self.callback = callback
        super.init()
    }

    @objc func handleDisplayLink(_ displayLink: CADisplayLink) {
        callback(displayLink)
    }
}

private final class StatsAllTimeSummaryCardView: UIView {
    private let containerView = StatsMomentumCardContainerView()
    private let segmentedControl = UISegmentedControl(items: ["ALL TIME", "THIS WEEK"])
    private let readingTimeColumn = StatsSummaryColumnView()
    private let booksColumn = StatsSummaryColumnView()

    var periodChanged: ((StatsSummaryPeriod) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubviewForConstraints(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.setTitleTextAttributes([
            .font: Fonts.semiBold13,
            .foregroundColor: Colours.textSecondary
        ], for: .normal)
        segmentedControl.setTitleTextAttributes([
            .font: Fonts.semiBold13,
            .foregroundColor: Colours.textPrimary
        ], for: .selected)
        segmentedControl.addTarget(self, action: #selector(handleSegmentChanged), for: .valueChanged)

        let statsRow = UIStackView(arrangedSubviews: [readingTimeColumn, booksColumn])
        statsRow.axis = .horizontal
        statsRow.spacing = 20
        statsRow.alignment = .fill
        statsRow.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [segmentedControl, statsRow])
        stack.axis = .vertical
        stack.spacing = 18
        stack.alignment = .fill

        containerView.addSubviewForConstraints(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }

    func configure(with viewModel: StatsMomentumViewModel.AllTime) {
        segmentedControl.selectedSegmentIndex = viewModel.selectedPeriod == .allTime ? 0 : 1
        readingTimeColumn.configure(title: "Listening Time", value: viewModel.readingTimeLine, percentile: viewModel.readingTimePercentile)
        booksColumn.configure(title: "Books Completed", value: viewModel.booksLine, badgeState: viewModel.booksBadgeState)
    }

    @objc private func handleSegmentChanged() {
        let period: StatsSummaryPeriod = segmentedControl.selectedSegmentIndex == 0 ? .allTime : .thisWeek
        periodChanged?(period)
    }
}

private final class StatsSummaryColumnView: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let percentileBadge = PercentileBadgeView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        titleLabel.font = Fonts.regular14
        titleLabel.textColor = Colours.textSecondary
        titleLabel.numberOfLines = 0

        valueLabel.font = Fonts.semiBold19
        valueLabel.textColor = Colours.textPrimary
        valueLabel.numberOfLines = 2

        percentileBadge.isHidden = true
        percentileBadge.setContentHuggingPriority(.required, for: .horizontal)
        percentileBadge.setContentCompressionResistancePriority(.required, for: .horizontal)

        let badgeRow = UIStackView(arrangedSubviews: [percentileBadge, UIView()])
        badgeRow.axis = .horizontal
        badgeRow.alignment = .center

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel, badgeRow])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading

        addSubviewForConstraints(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(title: String, value: String, percentile: Int?) {
        titleLabel.text = title
        valueLabel.text = value

        if let percentile {
            percentileBadge.isHidden = false
            percentileBadge.configure(percentile: percentile)
        } else {
            percentileBadge.isHidden = true
        }
    }

    func configure(title: String, value: String, badgeState: PercentileBadgeState?) {
        titleLabel.text = title
        valueLabel.text = value
        if let badgeState {
            percentileBadge.isHidden = false
            percentileBadge.configure(state: badgeState)
        } else {
            percentileBadge.isHidden = true
        }
    }
}

// MARK: - UserPercentiles Model

struct UserPercentiles {
    let totalTimePercentile: Int
    let weeklyTimePercentile: Int
    let totalBooksPercentile: Int
    let weeklyBooksPercentile: Int
}
