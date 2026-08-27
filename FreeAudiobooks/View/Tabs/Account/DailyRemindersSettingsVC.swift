//
//  DailyRemindersSettingsVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 31/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import UserNotifications

/// Settings screen for managing daily listening reminders
/// Allows users to enable/disable reminders and change the reminder time
class DailyRemindersSettingsVC: UIViewController {

    // MARK: - State

    private let notificationsVariant = OnboardingNotificationsVariant.current
    private var remindersWereEnabledOnLoad: Bool = false

    private var selectedTime: ReminderTime = .evening {
        didSet {
            updateChipSelection()
            updateNotificationPreview()
        }
    }

    private var customHour: Int = 20
    private var customMinute: Int = 0
    private var goalMinutes: Int = 15
    private var tilesSelectionState = ReminderTilesSelectionState(
        selectedTime: .evening,
        customHour: 20,
        customMinute: 0
    )

    // MARK: - UI Elements

    private let contentView = UIView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = Colours.textPrimary
        label.textAlignment = .left
        label.numberOfLines = 0
        label.text = "We'll help you reach your listening goals"
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = Colours.subtext
        label.textAlignment = .left
        label.numberOfLines = 0
        label.text = "Pick a time that works for your schedule."
        return label
    }()

    private lazy var timeChipsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        return stack
    }()

    private lazy var morningChip: SettingsTimeChipView = {
        let chip = SettingsTimeChipView(time: .morning)
        chip.addTarget(self, action: #selector(timeChipTapped(_:)), for: .touchUpInside)
        return chip
    }()

    private lazy var afternoonChip: SettingsTimeChipView = {
        let chip = SettingsTimeChipView(time: .afternoon)
        chip.addTarget(self, action: #selector(timeChipTapped(_:)), for: .touchUpInside)
        return chip
    }()

    private lazy var eveningChip: SettingsTimeChipView = {
        let chip = SettingsTimeChipView(time: .evening)
        chip.addTarget(self, action: #selector(timeChipTapped(_:)), for: .touchUpInside)
        return chip
    }()

    private lazy var customChip: SettingsCustomTimeChipView = {
        let chip = SettingsCustomTimeChipView()
        chip.addTarget(self, action: #selector(customChipTapped), for: .touchUpInside)
        return chip
    }()

    private lazy var notificationPreviewCard: SettingsNotificationPreviewCard = {
        let card = SettingsNotificationPreviewCard()
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

    private let calAICTAAreaBg = UIColor.dynamic(
        light: UIColor(red: 252/255, green: 252/255, blue: 252/255, alpha: 1), // #FCFCFC
        dark: Colours.surfacePrimary
    )

    private lazy var bottomContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = calAICTAAreaBg
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var saveButton: UIButton = {
        let button = Buttons.primaryCTA(buttonTitle: "Save")
        button.layer.cornerRadius = UIConstants.shared.onboardingButtonCornerRadius
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        loadCurrentState()

        AnalyticsManager.shared.trackViewedDailyReminderSettings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard NavigationBarStyler.reapplyIfNeeded(on: self, previousTraitCollection: previousTraitCollection) else { return }
        setupNavigation()
        setupDisableButtonIfNeeded()
    }

    // MARK: - Setup

    private func setupNavigation() {
        navigationItem.title = "Listening Reminders"
        view.backgroundColor = Colours.surfacePrimary

        guard let navigationBar = navigationController?.navigationBar else { return }
        NavigationBarStyler.apply(to: navigationBar)

        // Back button
        let btnLeftMenu = UIButton(type: .system)
        let backImage = UIImage(named: "backButtonNavIcon")?.withRenderingMode(.alwaysTemplate)
        btnLeftMenu.setImage(backImage, for: .normal)
        btnLeftMenu.tintColor = Colours.textPrimary
        btnLeftMenu.addTarget(self, action: #selector(popVC), for: .touchUpInside)
        let barButton = UIBarButtonItem(customView: btnLeftMenu)
        navigationItem.leftBarButtonItem = barButton

    }

    private func setupDisableButtonIfNeeded() {
        guard remindersWereEnabledOnLoad else { return }

        let disableButton = UIBarButtonItem(
            title: "Disable",
            style: .plain,
            target: self,
            action: #selector(disableTapped)
        )
        disableButton.setTitleTextAttributes([
            .font: Fonts.navBarTitleTextAttributes[.font] as Any,
            .foregroundColor: Colours.subtext
        ], for: .normal)
        navigationItem.rightBarButtonItem = disableButton
    }

    private func setupUI() {
        view.addSubviewForConstraints(contentView)
        view.addSubview(bottomContainerView)
        bottomContainerView.addSubviewForConstraints(saveButton)

        contentView.addSubviewForConstraints(titleLabel)
        contentView.addSubviewForConstraints(subtitleLabel)

        switch notificationsVariant {
        case .original:
            timeChipsStackView.addArrangedSubview(morningChip)
            timeChipsStackView.addArrangedSubview(afternoonChip)
            timeChipsStackView.addArrangedSubview(eveningChip)
            contentView.addSubviewForConstraints(timeChipsStackView)
            contentView.addSubviewForConstraints(customChip)
            contentView.addSubviewForConstraints(notificationPreviewCard)
        case .tiles:
            contentView.addSubviewForConstraints(tilesStackView)
        }

        contentView.addSubviewForConstraints(consistencyStatCard)

        let margin: CGFloat = UIConstants.shared.standardMargin

        NSLayoutConstraint.activate([
            // Bottom container
            bottomContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Save button
            saveButton.topAnchor.constraint(equalTo: bottomContainerView.topAnchor, constant: 16),
            saveButton.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor, constant: margin),
            saveButton.trailingAnchor.constraint(equalTo: bottomContainerView.trailingAnchor, constant: -margin),
            saveButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.onboardingButtonHeight),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -margin),

            // ContentView
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomContainerView.topAnchor),

            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: margin),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),

            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),

            // Listening consistency stat - fixed just above the Save area
            consistencyStatCard.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            consistencyStatCard.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: margin),
            consistencyStatCard.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -margin),
            consistencyStatCard.widthAnchor.constraint(lessThanOrEqualToConstant: 300),
            consistencyStatCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])

        switch notificationsVariant {
        case .original:
            NSLayoutConstraint.activate([
                timeChipsStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
                timeChipsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
                timeChipsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
                timeChipsStackView.heightAnchor.constraint(equalToConstant: 44),

                customChip.topAnchor.constraint(equalTo: timeChipsStackView.bottomAnchor, constant: 16),
                customChip.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
                customChip.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
                customChip.heightAnchor.constraint(equalToConstant: 32),

                notificationPreviewCard.topAnchor.constraint(equalTo: customChip.bottomAnchor, constant: 24),
                notificationPreviewCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
                notificationPreviewCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
                notificationPreviewCard.bottomAnchor.constraint(lessThanOrEqualTo: consistencyStatCard.topAnchor, constant: -16)
            ])
        case .tiles:
            NSLayoutConstraint.activate([
                tilesStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
                tilesStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
                tilesStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
                tilesStackView.heightAnchor.constraint(equalToConstant: 216),
                tilesStackView.bottomAnchor.constraint(lessThanOrEqualTo: consistencyStatCard.topAnchor, constant: -16)
            ])
        }
    }

    private func loadCurrentState() {
        // Check if reminders are currently scheduled
        DailyReminderScheduler.hasDailyReminderScheduled { [weak self] hasReminder in
            guard let self = self else { return }
            print("📅 Listening Reminders - hasReminder: \(hasReminder)")
            DispatchQueue.main.async {
                self.remindersWereEnabledOnLoad = hasReminder
                self.setupDisableButtonIfNeeded()
            }
        }

        // Load saved preferences
        if let reminderTimeString = NewOnboardingUserDefaults.getSelectedReminderTime(),
           let reminderTime = ReminderTime(rawValue: reminderTimeString) {
            selectedTime = reminderTime
        }

        if let customTime = NewOnboardingUserDefaults.getCustomReminderTime() {
            customHour = customTime.hour
            customMinute = customTime.minute
            if notificationsVariant == .original && selectedTime == .custom {
                customChip.setCustomTime(hour: customHour, minute: customMinute)
            }
        }

        if let goal = NewOnboardingUserDefaults.getDailyListeningGoal() {
            goalMinutes = goal
        }

        if notificationsVariant == .tiles {
            tilesSelectionState = ReminderTilesSelectionState(
                selectedTime: selectedTime,
                customHour: customHour,
                customMinute: customMinute
            )
        }

        updateChipSelection()
        updateNotificationPreview()
    }

    // MARK: - UI Updates

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
        updateTileSelection()
    }

    // MARK: - Actions

    @objc private func popVC() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func disableTapped() {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()

        DailyReminderScheduler.cancelDailyReminder()
        OnboardingRetentionScheduler.cancelAll(reason: "userDisabledReminders")
        AnalyticsManager.shared.trackDisabledDailyReminders()

        navigationController?.popViewController(animated: true)
    }

    @objc private func timeChipTapped(_ sender: SettingsTimeChipView) {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
        selectedTime = sender.time

        // Clear custom time if switching to a preset
        customChip.reset()
        customHour = 20
        customMinute = 0
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
        customChip.setCustomTime(hour: customHour, minute: customMinute)
        updateNotificationPreview()

        presentTimePicker(initialHour: customHour, initialMinute: customMinute) { [weak self] hour, minute in
            guard let self = self else { return }
            self.customHour = hour
            self.customMinute = minute
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

    @objc private func saveTapped() {
        HapticFeedbackHelper.shared.triggerSuccessHaptic()

        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    self.saveAndSchedule()
                case .notDetermined:
                    self.requestPermissionThenSave()
                case .denied:
                    self.showPermissionDeniedAlert()
                case .ephemeral:
                    self.saveAndSchedule()
                @unknown default:
                    self.saveAndSchedule()
                }
            }
        }
    }

    private func requestPermissionThenSave() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if granted {
                    let appDelegate = UIApplication.shared.delegate as? AppDelegate
                    appDelegate?.registerForFreeAudiobooksRemoteNotifications()
                    AnalyticsManager.shared.trackPushPermissionGranted()
                    
                    self.saveAndSchedule()
                } else {
                    self.showPermissionDeniedAlert()
                }
            }
        }
    }

    private func saveAndSchedule() {
        // Save preferences
        NewOnboardingUserDefaults.saveSelectedReminderTime(selectedTime.rawValue)
        NewOnboardingUserDefaults.saveCustomReminderTime(hour: customHour, minute: customMinute)

        // Schedule the daily reminder, then immediately re-evaluate retention overlap.
        if selectedTime == .custom {
            DailyReminderScheduler.scheduleDaily(
                at: selectedTime,
                goalMinutes: goalMinutes,
                customHour: customHour,
                customMinute: customMinute
            )
        } else {
            DailyReminderScheduler.scheduleDaily(at: selectedTime, goalMinutes: goalMinutes)
        }
        OnboardingRetentionScheduler.refreshRemainingNudges()

        AnalyticsManager.shared.trackSavedDailyReminderSettings()
        navigationController?.popViewController(animated: true)
    }

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Notifications Disabled",
            message: "To receive listening reminders, please enable notifications in Settings.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        present(alert, animated: true)
    }
}

// MARK: - SettingsTimeChipView

/// A selectable chip for choosing reminder time
private class SettingsTimeChipView: UIControl {

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

        switch time {
        case .morning:
            titleLabel.text = "Morning\n8 AM"
        case .afternoon:
            titleLabel.text = "Afternoon\n1 PM"
        case .evening:
            titleLabel.text = "Evening\n8 PM"
        case .custom:
            titleLabel.text = "Custom"
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

// MARK: - SettingsCustomTimeChipView

/// A secondary text-link style control for custom time selection
private class SettingsCustomTimeChipView: UIControl {

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
        formatter.timeStyle = .short
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

// MARK: - SettingsNotificationPreviewCard

/// iOS lock screen style notification preview
private class SettingsNotificationPreviewCard: UIView {

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
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),

            appIconView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            appIconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            appIconView.widthAnchor.constraint(equalToConstant: 36),
            appIconView.heightAnchor.constraint(equalToConstant: 36),

            appNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            appNameLabel.leadingAnchor.constraint(equalTo: appIconView.trailingAnchor, constant: 10),

            timeLabel.centerYAnchor.constraint(equalTo: appNameLabel.centerYAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            notificationTitleLabel.topAnchor.constraint(equalTo: appNameLabel.bottomAnchor, constant: 4),
            notificationTitleLabel.leadingAnchor.constraint(equalTo: appIconView.trailingAnchor, constant: 10),
            notificationTitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            notificationBodyLabel.topAnchor.constraint(equalTo: notificationTitleLabel.bottomAnchor, constant: 2),
            notificationBodyLabel.leadingAnchor.constraint(equalTo: appIconView.trailingAnchor, constant: 10),
            notificationBodyLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            notificationBodyLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }

    func configure(goalMinutes: Int, reminderTime: ReminderTime) {
        notificationTitleLabel.text = "Time for your \(goalMinutes)-minute listen"

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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        backgroundColor = previewWrapperBackgroundColor
        containerView.backgroundColor = UIColor.dynamic(light: Colours.surfacePrimary, dark: Colours.surfaceCard)
        containerView.layer.shadowColor = Colours.shadowBase.cgColor
    }
}
