//
//  ReminderTimeSelectionComponents.swift
//  FreeAudiobooks
//
//  Shared reminder-time selection UI and state used by onboarding and Account.
//

import UIKit

enum ReminderTimeTilePeriod: CaseIterable, Equatable {
    case morning
    case day
    case evening

    var title: String {
        switch self {
        case .morning: return "Morning"
        case .day: return "Day"
        case .evening: return "Evening"
        }
    }

    var symbolName: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .day: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        }
    }

    var presetTime: ReminderTime {
        switch self {
        case .morning: return .morning
        case .day: return .afternoon
        case .evening: return .evening
        }
    }

    var defaultHour: Int { presetTime.hour }
    var defaultMinute: Int { 0 }

    static func period(forHour hour: Int, minute: Int) -> ReminderTimeTilePeriod {
        switch hour {
        case 5..<12: return .morning
        case 12..<18: return .day
        default: return .evening
        }
    }
}

struct ReminderTilesSelectionState: Equatable {
    private(set) var selectedTime: ReminderTime
    private(set) var customHour: Int
    private(set) var customMinute: Int

    var selectedPeriod: ReminderTimeTilePeriod {
        switch selectedTime {
        case .morning: return .morning
        case .afternoon: return .day
        case .evening: return .evening
        case .custom:
            return .period(forHour: customHour, minute: customMinute)
        }
    }

    init(selectedTime: ReminderTime, customHour: Int, customMinute: Int) {
        self.selectedTime = selectedTime
        self.customHour = customHour
        self.customMinute = customMinute
    }

    mutating func selectPreset(_ period: ReminderTimeTilePeriod) {
        selectedTime = period.presetTime
        customHour = ReminderTime.evening.hour
        customMinute = 0
    }

    /// Selects the tapped row and returns the time the picker should initially display.
    /// An existing custom value is retained when its own row is edited.
    mutating func beginEditing(_ period: ReminderTimeTilePeriod) -> (hour: Int, minute: Int) {
        if selectedTime == .custom && selectedPeriod == period {
            return (customHour, customMinute)
        }

        selectPreset(period)
        return (period.defaultHour, period.defaultMinute)
    }

    mutating func applyCustomTime(hour: Int, minute: Int) {
        selectedTime = .custom
        customHour = hour
        customMinute = minute
    }

    func displayedTime(for period: ReminderTimeTilePeriod) -> (hour: Int, minute: Int) {
        if selectedTime == .custom && selectedPeriod == period {
            return (customHour, customMinute)
        }
        return (period.defaultHour, period.defaultMinute)
    }
}

final class ReminderTimeTileView: UIControl {

    let period: ReminderTimeTilePeriod
    var onTimeButtonTapped: (() -> Void)?

    override var isSelected: Bool {
        didSet { updateAppearance() }
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(
                withDuration: 0.1,
                delay: 0,
                options: [.allowUserInteraction, .curveEaseOut],
                animations: {
                    self.transform = self.isHighlighted
                        ? CGAffineTransform(scaleX: 0.98, y: 0.98)
                        : .identity
                }
            )
        }
    }

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
        return label
    }()

    private let timeButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        return button
    }()

    private let selectionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        return imageView
    }()

    init(period: ReminderTimeTilePeriod) {
        self.period = period
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        layer.cornerRadius = 14
        layer.borderWidth = 1

        iconImageView.image = UIImage(systemName: period.symbolName)
        titleLabel.text = period.title
        timeButton.addTarget(self, action: #selector(timeButtonTapped), for: .touchUpInside)

        addSubviewForConstraints(iconImageView)
        addSubviewForConstraints(titleLabel)
        addSubviewForConstraints(timeButton)
        addSubviewForConstraints(selectionImageView)

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeButton.leadingAnchor, constant: -8),

            selectionImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            selectionImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            selectionImageView.widthAnchor.constraint(equalToConstant: 24),
            selectionImageView.heightAnchor.constraint(equalToConstant: 24),

            timeButton.trailingAnchor.constraint(equalTo: selectionImageView.leadingAnchor, constant: -10),
            timeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            timeButton.heightAnchor.constraint(equalToConstant: 40),
            timeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 78)
        ])

        isAccessibilityElement = true
        accessibilityLabel = period.title
        accessibilityHint = "Select this reminder time. Use the Adjust time action to choose another time."
        accessibilityIdentifier = "reminderTile.\(period.title.lowercased())"
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(
                name: "Adjust time",
                target: self,
                selector: #selector(accessibilityAdjustTime)
            )
        ]
        timeButton.accessibilityLabel = "Adjust \(period.title.lowercased()) reminder time"

        setTime(hour: period.defaultHour, minute: period.defaultMinute)
        updateAppearance()
    }

    func setTime(hour: Int, minute: Int) {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let formattedTime = Calendar.current.date(from: components).map(formatter.string(from:)) ?? ""

        timeButton.setTitle(formattedTime, for: .normal)
        timeButton.accessibilityValue = formattedTime
        accessibilityValue = formattedTime
    }

    @objc private func timeButtonTapped() {
        onTimeButtonTapped?()
    }

    @objc private func accessibilityAdjustTime() -> Bool {
        onTimeButtonTapped?()
        return true
    }

    private func updateAppearance() {
        if isSelected {
            backgroundColor = Colours.ctaBackground
            layer.borderColor = Colours.ctaBackground.cgColor
            iconImageView.tintColor = Colours.ctaForeground
            titleLabel.textColor = Colours.ctaForeground
            timeButton.backgroundColor = Colours.ctaForeground.withAlphaComponent(0.14)
            timeButton.setTitleColor(Colours.ctaForeground, for: .normal)
            selectionImageView.image = UIImage(systemName: "checkmark.circle.fill")
            selectionImageView.tintColor = Colours.ctaForeground
            accessibilityTraits = [.button, .selected]
        } else {
            backgroundColor = Colours.surfaceCard
            layer.borderColor = Colours.inputBorder.cgColor
            iconImageView.tintColor = Colours.textSecondary
            titleLabel.textColor = Colours.textPrimary
            timeButton.backgroundColor = Colours.surfacePrimary
            timeButton.setTitleColor(Colours.textPrimary, for: .normal)
            selectionImageView.image = UIImage(systemName: "circle")
            selectionImageView.tintColor = Colours.textTertiary
            accessibilityTraits = [.button]
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateAppearance()
    }
}

/// Half-sheet modal for selecting a custom reminder time.
final class ReminderTimePickerSheetVC: UIViewController {

    var onTimeSelected: ((Int, Int) -> Void)?
    var onTimeChanged: ((Int, Int) -> Void)?

    private var initialHour: Int
    private var initialMinute: Int

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = Colours.textPrimary
        label.text = "Set reminder time"
        label.textAlignment = .center
        return label
    }()

    private lazy var timePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.minuteInterval = 5
        return picker
    }()

    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = Colours.ctaBackground
        button.setTitleColor(Colours.ctaForeground, for: .normal)
        button.layer.cornerRadius = 26
        button.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        return button
    }()

    init(hour: Int, minute: Int) {
        self.initialHour = hour
        self.initialMinute = minute
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        var components = DateComponents()
        components.hour = initialHour
        components.minute = initialMinute
        if let date = Calendar.current.date(from: components) {
            timePicker.date = date
        }

        timePicker.addTarget(self, action: #selector(timePickerValueChanged), for: .valueChanged)
    }

    @objc private func timePickerValueChanged() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: timePicker.date)
        let hour = components.hour ?? 20
        let minute = components.minute ?? 0
        onTimeChanged?(hour, minute)
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubviewForConstraints(titleLabel)
        view.addSubviewForConstraints(timePicker)
        view.addSubviewForConstraints(doneButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            timePicker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            timePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            doneButton.topAnchor.constraint(equalTo: timePicker.bottomAnchor, constant: 24),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    @objc private func doneTapped() {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()

        let components = Calendar.current.dateComponents([.hour, .minute], from: timePicker.date)
        let hour = components.hour ?? 20
        let minute = components.minute ?? 0

        onTimeSelected?(hour, minute)
        dismiss(animated: true)
    }
}
