//
//  PushNotificationVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import UserNotifications

/// Daily listening reminder setup screen (Screen 13)
/// Lets users pick their preferred reminder time and shows a notification preview
class PushNotificationVC: BaseNewOnboardingVC {

    override var step: NewOnboardingStep { .pushNotification }
    override var showsContinueButton: Bool { true }
    override var showsSecondaryAction: Bool { true }
    override var secondaryActionTitle: String? { "Not now" }

    private let notificationsVariant = OnboardingNotificationsVariant.current

    // MARK: - UI Elements

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = Colours.textPrimary
        label.textAlignment = .left
        label.numberOfLines = 0
        label.text = "Reminders help you hit your daily goal"
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = Colours.subtext
        label.textAlignment = .left
        label.numberOfLines = 0
        label.text = "One gentle reminder daily—pick a time."
        return label
    }()

    private lazy var timeChipsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        return stack
    }()

    private lazy var morningChip: TimeChipView = {
        let chip = TimeChipView(time: .morning)
        chip.addTarget(self, action: #selector(timeChipTapped(_:)), for: .touchUpInside)
        return chip
    }()

    private lazy var afternoonChip: TimeChipView = {
        let chip = TimeChipView(time: .afternoon)
        chip.addTarget(self, action: #selector(timeChipTapped(_:)), for: .touchUpInside)
        return chip
    }()

    private lazy var eveningChip: TimeChipView = {
        let chip = TimeChipView(time: .evening)
        chip.addTarget(self, action: #selector(timeChipTapped(_:)), for: .touchUpInside)
        return chip
    }()

    private lazy var customChip: CustomTimeChipView = {
        let chip = CustomTimeChipView()
        chip.addTarget(self, action: #selector(customChipTapped), for: .touchUpInside)
        return chip
    }()

    private lazy var notificationPreviewCard: NotificationPreviewCard = {
        let card = NotificationPreviewCard()
        return card
    }()

    private let consistencyStatCard = ReminderConsistencyStatCard(
        text: RCValues.shared.string(forKey: .onbPushNotificationConsistencyStat)
    )

    private lazy var tilesStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [morningTile, dayTile, eveningTile])
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fillEqually
        return stack
    }()

    private lazy var morningTile: ReminderTimeTileView = makeReminderTile(for: .morning)
    private lazy var dayTile: ReminderTimeTileView = makeReminderTile(for: .day)
    private lazy var eveningTile: ReminderTimeTileView = makeReminderTile(for: .evening)

    // MARK: - State

    private var selectedTime: ReminderTime = .evening {
        didSet {
            updateChipSelection()
            updateNotificationPreview()
        }
    }

    private var customHour: Int = 20
    private var customMinute: Int = 0
    private var tilesSelectionState = ReminderTilesSelectionState(
        selectedTime: .evening,
        customHour: 20,
        customMinute: 0
    )

    private var hasAnimatedEntrance = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        // Restore previously selected time and custom values
        selectedTime = coordinator.dataStore.selectedReminderTime
        customHour = coordinator.dataStore.customReminderHour
        customMinute = coordinator.dataStore.customReminderMinute

        if notificationsVariant == .tiles {
            tilesSelectionState = ReminderTilesSelectionState(
                selectedTime: selectedTime,
                customHour: customHour,
                customMinute: customMinute
            )
            updateTileSelection()
        } else if selectedTime == .custom {
            // Update custom chip label if custom time was previously set
            customChip.setCustomTime(hour: customHour, minute: customMinute)
        }

        updateNotificationPreview()
    }

    override func configureButtonState() {
        setContinueButtonEnabled(true)
        setContinueButtonTitle("Enable Reminders")
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        if parent != nil && !hasAnimatedEntrance {
            hasAnimatedEntrance = true
            // Small delay to ensure views are laid out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.animateEntrance()
            }
        }
    }

    // MARK: - Entrance Animation

    private func animateEntrance() {
        switch notificationsVariant {
        case .original:
            animateOriginalEntrance()
        case .tiles:
            animateTilesEntrance()
        }
    }

    private func animateOriginalEntrance() {
        let presetChips: [UIView] = [morningChip, afternoonChip, eveningChip]

        // Animate preset chips with staggered delay
        for (index, chip) in presetChips.enumerated() {
            let delay = Double(index) * 0.08  // 80ms stagger
            UIView.animate(
                withDuration: 0.4,
                delay: delay,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.3,
                options: [.curveEaseOut],
                animations: {
                    chip.alpha = 1
                    chip.transform = .identity
                }
            )
        }

        // Animate custom chip after preset chips
        UIView.animate(
            withDuration: 0.4,
            delay: 0.24,  // After the 3 preset chips
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.3,
            options: [.curveEaseOut],
            animations: {
                self.customChip.alpha = 1
                self.customChip.transform = .identity
            }
        )

        // Animate notification preview card after chips
        UIView.animate(
            withDuration: 0.5,
            delay: 0.35,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.2,
            options: [.curveEaseOut],
            animations: {
                self.notificationPreviewCard.alpha = 1
                self.notificationPreviewCard.transform = .identity
            }
        )

        // Fade in consistency stat card
        UIView.animate(
            withDuration: 0.3,
            delay: 0.55,
            options: [.curveEaseOut],
            animations: {
                self.consistencyStatCard.alpha = 1
            }
        )
    }

    private func animateTilesEntrance() {
        for (index, tile) in reminderTiles.enumerated() {
            UIView.animate(
                withDuration: 0.4,
                delay: Double(index) * 0.08,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.3,
                options: [.curveEaseOut],
                animations: {
                    tile.alpha = 1
                    tile.transform = .identity
                }
            )
        }

        UIView.animate(
            withDuration: 0.3,
            delay: 0.35,
            options: [.curveEaseOut],
            animations: {
                self.consistencyStatCard.alpha = 1
            }
        )
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.addSubviewForConstraints(titleLabel)
        contentView.addSubviewForConstraints(subtitleLabel)

        let margin = UIConstants.shared.standardMargin

        NSLayoutConstraint.activate([
            // Title - left aligned
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),

            // Subtitle - left aligned
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin)
        ])

        switch notificationsVariant {
        case .original:
            setupOriginalControls(margin: margin)
        case .tiles:
            setupTilesControls(margin: margin)
        }

        contentView.addSubviewForConstraints(consistencyStatCard)
        NSLayoutConstraint.activate([
            consistencyStatCard.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            consistencyStatCard.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: margin),
            consistencyStatCard.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -margin),
            consistencyStatCard.widthAnchor.constraint(lessThanOrEqualToConstant: 300),
            consistencyStatCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])

        // Set initial state for entrance animations
        prepareForEntranceAnimation()
    }

    private func setupOriginalControls(margin: CGFloat) {
        timeChipsStackView.addArrangedSubview(morningChip)
        timeChipsStackView.addArrangedSubview(afternoonChip)
        timeChipsStackView.addArrangedSubview(eveningChip)

        contentView.addSubviewForConstraints(timeChipsStackView)
        contentView.addSubviewForConstraints(customChip)
        contentView.addSubviewForConstraints(notificationPreviewCard)

        NSLayoutConstraint.activate([
            timeChipsStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 28),
            timeChipsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            timeChipsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            timeChipsStackView.heightAnchor.constraint(equalToConstant: 44),

            customChip.topAnchor.constraint(equalTo: timeChipsStackView.bottomAnchor, constant: 16),
            customChip.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            customChip.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            customChip.heightAnchor.constraint(equalToConstant: 32),

            notificationPreviewCard.topAnchor.constraint(equalTo: customChip.bottomAnchor, constant: 24),
            notificationPreviewCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            notificationPreviewCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin)
        ])
    }

    private func setupTilesControls(margin: CGFloat) {
        contentView.addSubviewForConstraints(tilesStackView)

        NSLayoutConstraint.activate([
            tilesStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 28),
            tilesStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            tilesStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            tilesStackView.heightAnchor.constraint(equalToConstant: 216)
        ])
    }

    private func prepareForEntranceAnimation() {
        switch notificationsVariant {
        case .original:
            morningChip.alpha = 0
            morningChip.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            afternoonChip.alpha = 0
            afternoonChip.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            eveningChip.alpha = 0
            eveningChip.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)

            customChip.alpha = 0
            customChip.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)

            notificationPreviewCard.alpha = 0
            notificationPreviewCard.transform = CGAffineTransform(translationX: 0, y: 20)
        case .tiles:
            reminderTiles.forEach { tile in
                tile.alpha = 0
                tile.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }
        }

        // Consistency stat card starts hidden
        consistencyStatCard.alpha = 0
    }

    private func updateChipSelection() {
        switch notificationsVariant {
        case .original:
            morningChip.isSelected = (selectedTime == .morning)
            afternoonChip.isSelected = (selectedTime == .afternoon)
            eveningChip.isSelected = (selectedTime == .evening)
            customChip.isSelected = (selectedTime == .custom)
        case .tiles:
            updateTileSelection()
        }
    }

    private func updateNotificationPreview() {
        guard notificationsVariant == .original else { return }
        let goalMinutes = coordinator.dataStore.dailyListeningGoal ?? 15
        if selectedTime == .custom {
            notificationPreviewCard.configure(goalMinutes: goalMinutes, customHour: customHour, customMinute: customMinute)
        } else {
            notificationPreviewCard.configure(goalMinutes: goalMinutes, reminderTime: selectedTime)
        }
    }

    private var reminderTiles: [ReminderTimeTileView] {
        [morningTile, dayTile, eveningTile]
    }

    private func makeReminderTile(for period: ReminderTimeTilePeriod) -> ReminderTimeTileView {
        let tile = ReminderTimeTileView(period: period)
        tile.addTarget(self, action: #selector(reminderTileTapped(_:)), for: .touchUpInside)
        tile.onTimeButtonTapped = { [weak self] in
            self?.reminderTileTimeTapped(period)
        }
        return tile
    }

    private func updateTileSelection() {
        for tile in reminderTiles {
            let displayedTime = tilesSelectionState.displayedTime(for: tile.period)
            tile.setTime(hour: displayedTime.hour, minute: displayedTime.minute)
            tile.isSelected = tilesSelectionState.selectedPeriod == tile.period
        }
    }

    private func applyTilesSelectionState() {
        customHour = tilesSelectionState.customHour
        customMinute = tilesSelectionState.customMinute
        selectedTime = tilesSelectionState.selectedTime

        coordinator.dataStore.selectedReminderTime = selectedTime
        coordinator.dataStore.customReminderHour = customHour
        coordinator.dataStore.customReminderMinute = customMinute
        updateTileSelection()
    }

    // MARK: - Actions

    @objc private func timeChipTapped(_ sender: TimeChipView) {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
        selectedTime = sender.time
        coordinator.dataStore.selectedReminderTime = selectedTime

        // Clear custom time if switching to a preset
        customChip.reset()
        customHour = 20
        customMinute = 0
        coordinator.dataStore.customReminderHour = 20
        coordinator.dataStore.customReminderMinute = 0
    }

    @objc private func customChipTapped() {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
        presentTimePickerSheet()
    }

    @objc private func reminderTileTapped(_ sender: ReminderTimeTileView) {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
        tilesSelectionState.selectPreset(sender.period)
        applyTilesSelectionState()
    }

    private func reminderTileTimeTapped(_ period: ReminderTimeTilePeriod) {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
        let initialTime = tilesSelectionState.beginEditing(period)
        applyTilesSelectionState()

        presentTimePicker(
            initialHour: initialTime.hour,
            initialMinute: initialTime.minute
        ) { [weak self] hour, minute in
            guard let self = self else { return }
            self.tilesSelectionState.applyCustomTime(hour: hour, minute: minute)
            self.applyTilesSelectionState()
        }
    }

    private func presentTimePickerSheet() {
        // Immediately select custom and update UI
        selectedTime = .custom
        coordinator.dataStore.selectedReminderTime = .custom
        customChip.setCustomTime(hour: customHour, minute: customMinute)
        updateNotificationPreview()

        presentTimePicker(initialHour: customHour, initialMinute: customMinute) { [weak self] hour, minute in
            guard let self = self else { return }
            self.customHour = hour
            self.customMinute = minute
            self.coordinator.dataStore.customReminderHour = hour
            self.coordinator.dataStore.customReminderMinute = minute
            self.customChip.setCustomTime(hour: hour, minute: minute)
            self.updateNotificationPreview()
        }
    }

    private func presentTimePicker(
        initialHour: Int,
        initialMinute: Int,
        onTimeUpdated: @escaping (Int, Int) -> Void
    ) {
        let pickerVC = ReminderTimePickerSheetVC(hour: initialHour, minute: initialMinute)

        pickerVC.onTimeChanged = { hour, minute in
            onTimeUpdated(hour, minute)
        }
        pickerVC.onTimeSelected = { hour, minute in
            onTimeUpdated(hour, minute)
        }

        if let sheet = pickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }

        present(pickerVC, animated: true)
    }

    override func secondaryActionTapped() {
        // Skip without requesting permission
        coordinator.dataStore.didRequestPushPermission = false
        coordinator.dataStore.didGrantPushPermission = false
        AnalyticsManager.shared.trackOnbPushNotificationSkipped()
        coordinator.goToNextScreen()
    }

    override func continueButtonTapped() {
        trackContinueTapped()
        requestNotificationPermission()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }

                self.coordinator.dataStore.didRequestPushPermission = true
                self.coordinator.dataStore.didGrantPushPermission = granted

                if granted {
                    
                    let appDelegate = UIApplication.shared.delegate as? AppDelegate
                    appDelegate?.registerForFreeAudiobooksRemoteNotifications()
                    AnalyticsManager.shared.trackPushPermissionGranted()
                    
                    // Schedule the daily notification
                    let goalMinutes = self.coordinator.dataStore.dailyListeningGoal ?? 15
                    if self.selectedTime == .custom {
                        DailyReminderScheduler.scheduleDaily(
                            at: self.selectedTime,
                            goalMinutes: goalMinutes,
                            customHour: self.customHour,
                            customMinute: self.customMinute
                        )
                    } else {
                        DailyReminderScheduler.scheduleDaily(at: self.selectedTime, goalMinutes: goalMinutes)
                    }

                    // Create the retention window once, then only refresh any remaining nudges on revisits.
                    OnboardingRetentionScheduler.scheduleInitialNudges()

                    // Cancel any pending engagement notification (daily reminders take over)
                    EngagementEngine.cancelPendingNotification(includeStores: false)

                    AnalyticsManager.shared.trackOnbPushNotificationGranted()
                } else {
                    AnalyticsManager.shared.trackOnbPushNotificationDenied()
                }

                self.coordinator.goToNextScreen()
            }
        }
    }
}

// MARK: - TimeChipView

/// A selectable chip for choosing reminder time - iOS/premium style
class TimeChipView: UIControl {

    let time: ReminderTime

    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    init(time: ReminderTime) {
        self.time = time
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        layer.cornerRadius = 10
        layer.borderWidth = 1

        addSubviewForConstraints(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4)
        ])

        // Set text based on time
        switch time {
        case .morning:
            titleLabel.text = "Morning\n8 AM"
        case .afternoon:
            titleLabel.text = "Afternoon\n1 PM"
        case .evening:
            titleLabel.text = "Evening\n8 PM"
        case .custom:
            titleLabel.text = "Custom"  // Not used, but needed for exhaustive switch
        }

        updateAppearance()
    }

    private func updateAppearance() {
        if isSelected {
            backgroundColor = Colours.ctaBackground
            layer.borderColor = Colours.ctaBackground.cgColor
            titleLabel.textColor = Colours.ctaForeground
        } else {
            backgroundColor = Colours.surfaceCard
            layer.borderColor = Colours.inputBorder.cgColor
            titleLabel.textColor = Colours.textPrimary
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateAppearance()
    }
}

// MARK: - CustomTimeChipView

/// A secondary text-link style control for custom time selection
class CustomTimeChipView: UIControl {

    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    private var hasCustomTime = false

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.text = "Custom time…"
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubviewForConstraints(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8)
        ])

        updateAppearance()
    }

    func setCustomTime(hour: Int, minute: Int) {
        hasCustomTime = true
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        if let date = Calendar.current.date(from: components) {
            titleLabel.text = "Custom · \(formatter.string(from: date))"
        }
        updateAppearance()
    }

    func reset() {
        hasCustomTime = false
        titleLabel.text = "Custom time…"
        updateAppearance()
    }

    private func updateAppearance() {
        if isSelected || hasCustomTime {
            titleLabel.textColor = Colours.textPrimary
        } else {
            titleLabel.textColor = Colours.textSecondary
        }
    }
}

// MARK: - NotificationPreviewCard

/// iOS lock screen style notification preview
class NotificationPreviewCard: UIView {

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.dynamic(light: Colours.surfacePrimary, dark: Colours.surfaceCard)
        view.layer.cornerRadius = 14
        view.layer.shadowColor = Colours.shadowBase.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 6
        return view
    }()

    private let appIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        // Use app icon
        if let appIcon = UIImage(named: "AppIcon60x60") ?? UIImage(named: "AppIcon") {
            imageView.image = appIcon
        } else {
            imageView.backgroundColor = Colours.ctaBackground
        }
        return imageView
    }()

    private let appNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = Colours.textSecondary
        label.text = "FreeAudiobooks"
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = Colours.textTertiary
        return label
    }()

    private let notificationTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = Colours.textPrimary
        label.numberOfLines = 1
        return label
    }()

    private let notificationBodyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = Colours.textSecondary
        label.text = "Tap to continue where you left off."
        label.numberOfLines = 2
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var previewWrapperBackgroundColor: UIColor {
        UIColor.dynamic(light: Colours.surfaceSecondary, dark: UIColor.tertiarySystemBackground)
    }

    private func setupUI() {
        backgroundColor = previewWrapperBackgroundColor
        layer.cornerRadius = 16

        addSubviewForConstraints(containerView)
        containerView.addSubviewForConstraints(appIconView)
        containerView.addSubviewForConstraints(appNameLabel)
        containerView.addSubviewForConstraints(timeLabel)
        containerView.addSubviewForConstraints(notificationTitleLabel)
        containerView.addSubviewForConstraints(notificationBodyLabel)

        NSLayoutConstraint.activate([
            // Container with padding
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),

            // App icon
            appIconView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            appIconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            appIconView.widthAnchor.constraint(equalToConstant: 36),
            appIconView.heightAnchor.constraint(equalToConstant: 36),

            // App name
            appNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            appNameLabel.leadingAnchor.constraint(equalTo: appIconView.trailingAnchor, constant: 10),

            // Time label
            timeLabel.centerYAnchor.constraint(equalTo: appNameLabel.centerYAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            // Notification title
            notificationTitleLabel.topAnchor.constraint(equalTo: appNameLabel.bottomAnchor, constant: 4),
            notificationTitleLabel.leadingAnchor.constraint(equalTo: appIconView.trailingAnchor, constant: 10),
            notificationTitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            // Notification body
            notificationBodyLabel.topAnchor.constraint(equalTo: notificationTitleLabel.bottomAnchor, constant: 2),
            notificationBodyLabel.leadingAnchor.constraint(equalTo: appIconView.trailingAnchor, constant: 10),
            notificationBodyLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            notificationBodyLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        backgroundColor = previewWrapperBackgroundColor
        containerView.backgroundColor = UIColor.dynamic(light: Colours.surfacePrimary, dark: Colours.surfaceCard)
        containerView.layer.shadowColor = Colours.shadowBase.cgColor
    }

    func configure(goalMinutes: Int, reminderTime: ReminderTime) {
        notificationTitleLabel.text = "Time for your \(goalMinutes)-minute listen"

        // Format time based on selected reminder time (localized)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        var components = DateComponents()
        components.hour = reminderTime.hour
        components.minute = 0
        if let date = Calendar.current.date(from: components) {
            timeLabel.text = formatter.string(from: date)
        } else {
            timeLabel.text = ""
        }
    }

    func configure(goalMinutes: Int, customHour: Int, customMinute: Int) {
        notificationTitleLabel.text = "Time for your \(goalMinutes)-minute listen"

        // Format custom time (localized)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        var components = DateComponents()
        components.hour = customHour
        components.minute = customMinute
        if let date = Calendar.current.date(from: components) {
            timeLabel.text = formatter.string(from: date)
        } else {
            timeLabel.text = ""
        }
    }
}
