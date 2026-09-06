import UIKit

/// A visual interlude only: no account, recommendation or library work happens here.
final class SettingEverythingUpVC: BaseNewOnboardingVC {
    override var step: NewOnboardingStep { .settingEverythingUp }
    override var showsProgressBar: Bool { false }
    override var showsBackButton: Bool { false }
    override var showsContinueButton: Bool { false }
    override var contentTopInsetWithoutChrome: CGFloat { 0 }

    private var playback: SettingEverythingUpPlayback
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []
    private var isMounted = false
    private var hasTrackedView = false
    private(set) var didAdvance = false
    private(set) var percent = 0

    private let percentLabel = UILabel()
    private let statusLabel = UILabel()
    private let progressView = SetupGradientProgressView()
    private var rows: [(view: UIView, label: UILabel, tick: UIImageView)] = []

    init(coordinator: NewOnboardingCoordinator,
         schedule: SettingEverythingUpSchedule = SettingEverythingUpSchedule()) {
        playback = SettingEverythingUpPlayback(schedule: schedule)
        super.init(coordinator: coordinator)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        timer?.invalidate()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        let center = NotificationCenter.default
        observers = [
            center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
                self?.pause()
            },
            center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
                self?.startIfVisible()
            }
        ]
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        isMounted = parent != nil
        startIfVisible()
    }

    override func willMove(toParent parent: UIViewController?) {
        if parent == nil {
            isMounted = false
            playback.cancel()
            timer?.invalidate()
            timer = nil
        }
        super.willMove(toParent: parent)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startIfVisible()
    }

    override func viewWillDisappear(_ animated: Bool) {
        pause()
        super.viewWillDisappear(animated)
    }

    override func configureButtonState() {}

    // Base calls this during viewDidLoad; exposure is logged only after mounting.
    override func trackScreenViewed() {
        guard isMounted, viewIfLoaded?.window != nil, !hasTrackedView else { return }
        hasTrackedView = true
        super.trackScreenViewed()
    }

    private func startIfVisible() {
        guard isMounted, viewIfLoaded?.window != nil,
              UIApplication.shared.applicationState == .active,
              !playback.isCancelled, !playback.didComplete, timer == nil else { return }
        trackScreenViewed()
        playback.resume(at: ProcessInfo.processInfo.systemUptime)
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func pause() {
        playback.pause(at: ProcessInfo.processInfo.systemUptime)
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard isMounted, viewIfLoaded?.window != nil,
              UIApplication.shared.applicationState == .active else {
            pause()
            return
        }
        let finished = playback.tick(at: ProcessInfo.processInfo.systemUptime)
        apply(percent: playback.percent)
        if finished {
            timer?.invalidate()
            timer = nil
            guard !didAdvance else { return }
            didAdvance = coordinator.completeSetupScreen(self)
        }
    }

    // MARK: - Layout

    private func setupUI() {
        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = false
        scroll.showsVerticalScrollIndicator = false
        contentView.addSubviewForConstraints(scroll)

        let canvas = UIView()
        scroll.addSubviewForConstraints(canvas)
        let column = UIStackView()
        column.axis = .vertical
        column.spacing = 0
        canvas.addSubviewForConstraints(column)
        let center = column.centerYAnchor.constraint(equalTo: canvas.centerYAnchor)
        center.priority = .defaultHigh
        let height = canvas.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
        // Expand the scrollable canvas before compressing multiline labels.
        height.priority = .defaultLow
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: contentView.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            canvas.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            canvas.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            canvas.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            canvas.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            canvas.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
            canvas.heightAnchor.constraint(greaterThanOrEqualTo: scroll.frameLayoutGuide.heightAnchor),
            height,
            column.leadingAnchor.constraint(equalTo: canvas.leadingAnchor, constant: 24),
            column.trailingAnchor.constraint(equalTo: canvas.trailingAnchor, constant: -24),
            column.topAnchor.constraint(greaterThanOrEqualTo: canvas.topAnchor, constant: 24),
            column.bottomAnchor.constraint(lessThanOrEqualTo: canvas.bottomAnchor, constant: -24),
            center
        ])

        configure(percentLabel, font: .monospacedDigitSystemFont(ofSize: 64, weight: .bold), style: .largeTitle)
        percentLabel.text = "0%"
        percentLabel.textAlignment = .center
        // The changing number and the bar share a single accessible value.
        percentLabel.accessibilityLabel = "Setup progress"
        percentLabel.accessibilityValue = "0 percent"
        percentLabel.accessibilityTraits = .updatesFrequently

        let headline = UILabel()
        configure(headline, font: Fonts.boldWithSize(28), style: .title1)
        headline.text = RCValues.shared.string(forKey: .onbSettingEverythingUpTitle)
        headline.textAlignment = .center
        headline.accessibilityTraits = .header
        configure(statusLabel, font: Fonts.regular17, style: .body)
        statusLabel.textAlignment = .center
        statusLabel.textColor = Colours.textSecondary
        statusLabel.text = SettingEverythingUpSchedule.statusLine(at: 0)
        progressView.heightAnchor.constraint(equalToConstant: 10).isActive = true

        column.addArrangedSubview(percentLabel)
        column.setCustomSpacing(16, after: percentLabel)
        column.addArrangedSubview(headline)
        column.setCustomSpacing(32, after: headline)
        column.addArrangedSubview(progressView)
        column.setCustomSpacing(24, after: progressView)
        column.addArrangedSubview(statusLabel)
        column.setCustomSpacing(48, after: statusLabel)

        let list = UIStackView()
        list.axis = .vertical
        list.spacing = 16
        for text in SettingEverythingUpSchedule.checklist {
            let row = makeRow(text)
            rows.append(row)
            list.addArrangedSubview(row.view)
        }
        column.addArrangedSubview(list)
    }

    private func configure(_ label: UILabel, font: UIFont, style: UIFont.TextStyle) {
        label.font = UIFontMetrics(forTextStyle: style).scaledFont(for: font)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Colours.textPrimary
        label.numberOfLines = 0
    }

    private func makeRow(_ text: String) -> (view: UIView, label: UILabel, tick: UIImageView) {
        let row = UIView()
        row.isAccessibilityElement = true
        row.accessibilityLabel = text
        row.accessibilityValue = "Not yet"
        let label = UILabel()
        configure(label, font: Fonts.regular17, style: .body)
        label.text = text
        label.isAccessibilityElement = false
        let tick = UIImageView(image: UIImage(systemName: "circle"))
        tick.tintColor = Colours.separator
        tick.contentMode = .scaleAspectFit
        tick.isAccessibilityElement = false
        row.addSubviewForConstraints(label)
        row.addSubviewForConstraints(tick)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            label.topAnchor.constraint(equalTo: row.topAnchor),
            label.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            tick.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 16),
            tick.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            tick.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            tick.widthAnchor.constraint(equalToConstant: 22),
            tick.heightAnchor.constraint(equalToConstant: 22),
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: 24)
        ])
        return (row, label, tick)
    }

    // Internal so visual and accessibility states can be tested without waiting nine seconds.
    func apply(percent newPercent: Int) {
        let previous = percent
        percent = min(100, max(0, newPercent))
        guard percent != previous else { return }
        percentLabel.text = "\(percent)%"
        percentLabel.accessibilityValue = "\(percent) percent"
        progressView.setProgress(CGFloat(percent) / 100, animated: !UIAccessibility.isReduceMotionEnabled)
        let status = SettingEverythingUpSchedule.statusLine(at: percent)
        if status != statusLabel.text {
            statusLabel.text = status
            if viewIfLoaded?.window != nil {
                UIAccessibility.post(notification: .announcement, argument: status)
            }
        }
        for (index, threshold) in SettingEverythingUpSchedule.tickPercents.enumerated() {
            let done = percent >= threshold
            let row = rows[index]
            row.tick.image = UIImage(systemName: done ? "checkmark.circle.fill" : "circle")
            row.tick.tintColor = done ? Colours.textPrimary : Colours.separator
            row.view.accessibilityValue = done ? "Done" : "Not yet"
            if previous < threshold, done, !UIAccessibility.isReduceMotionEnabled {
                row.tick.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
                UIView.animate(withDuration: 0.25) { row.tick.transform = .identity }
            }
        }
    }
}

/// The same orange-to-pink colours as TryPlusChipView, clipped to a rounded fill.
private final class SetupGradientProgressView: UIView {
    private let fill = UIView()
    private let gradient = CAGradientLayer()
    private var progress: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Colours.separator
        clipsToBounds = true
        fill.clipsToBounds = true
        addSubview(fill)
        gradient.startPoint = CGPoint(x: 0, y: 0.4)
        gradient.endPoint = CGPoint(x: 1, y: 0.6)
        fill.layer.addSublayer(gradient)
        updateColors()
        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        fill.layer.cornerRadius = bounds.height / 2
        fill.frame = CGRect(x: 0, y: 0, width: bounds.width * progress, height: bounds.height)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradient.frame = fill.bounds
        CATransaction.commit()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }

    func setProgress(_ progress: CGFloat, animated: Bool) {
        self.progress = progress
        setNeedsLayout()
        if animated {
            UIView.animate(withDuration: 0.1, delay: 0, options: [.curveLinear, .beginFromCurrentState]) {
                self.layoutIfNeeded()
            }
        } else {
            layer.removeAllAnimations()
            fill.layer.removeAllAnimations()
            layoutIfNeeded()
        }
    }

    private func updateColors() {
        gradient.colors = [
            Colours.freebooksGradientStart.resolvedColor(with: traitCollection).cgColor,
            Colours.freebooksGradientEnd.resolvedColor(with: traitCollection).cgColor
        ]
    }
}
