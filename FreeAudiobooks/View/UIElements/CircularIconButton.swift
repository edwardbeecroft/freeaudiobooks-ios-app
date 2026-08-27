//
//  CircularIconButton.swift
//  FreeAudiobooks
//

import UIKit

class CircularIconButton: UIView {

    private let backgroundView = UIView()
    private let iconButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private var backgroundBottomConstraint: NSLayoutConstraint?
    private var titleLabelTopConstraint: NSLayoutConstraint?
    private var titleLabelBottomConstraint: NSLayoutConstraint?
    private var titleLabelCollapsedHeightConstraint: NSLayoutConstraint?
    private var progressLayer: CAShapeLayer?

    var tappedHandler: (() -> Void)?

    // MARK: - Configuration

    var iconTintColor: UIColor = Colours.actionIconForeground {
        didSet {
            iconButton.tintColor = iconTintColor
        }
    }

    var backgroundColour: UIColor = Colours.actionIconBackground {
        didSet {
            backgroundView.backgroundColor = backgroundColour
        }
    }

    var borderColor: UIColor? = nil {
        didSet {
            backgroundView.layer.borderColor = borderColor?.cgColor
        }
    }

    var borderWidth: CGFloat = 0 {
        didSet {
            backgroundView.layer.borderWidth = borderWidth
        }
    }

    // MARK: - Constants

    private let backgroundSize: CGFloat = 40
    private let iconSize: CGFloat = 20

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateProgressLayerPath()
    }

    convenience init(showLabel: Bool = true) {
        self.init(frame: .zero)
        setShowsLabel(showLabel)
    }

    // MARK: - Setup

    private func setupViews() {
        setupBackgroundView()
        setupIconButton()
        setupTitleLabel()
        setupTapGesture()
    }

    private func setupBackgroundView() {
        backgroundView.backgroundColor = backgroundColour
        backgroundView.layer.cornerRadius = backgroundSize / 2
        backgroundView.layer.masksToBounds = true
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.centerXAnchor.constraint(equalTo: centerXAnchor),
            backgroundView.widthAnchor.constraint(equalToConstant: backgroundSize),
            backgroundView.heightAnchor.constraint(equalToConstant: backgroundSize)
        ])

        backgroundBottomConstraint = backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
    }

    private func setupIconButton() {
        iconButton.imageView?.contentMode = .scaleAspectFit
        iconButton.tintColor = iconTintColor
        iconButton.isUserInteractionEnabled = false
        iconButton.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(iconButton)

        NSLayoutConstraint.activate([
            iconButton.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            iconButton.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
            iconButton.widthAnchor.constraint(equalToConstant: iconSize),
            iconButton.heightAnchor.constraint(equalToConstant: iconSize)
        ])
    }

    private func setupTitleLabel() {
        titleLabel.font = Fonts.medium15
        titleLabel.textColor = Colours.textSecondary
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        titleLabelTopConstraint = titleLabel.topAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: 6)
        titleLabelBottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        titleLabelCollapsedHeightConstraint = titleLabel.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            titleLabelTopConstraint!,
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabelBottomConstraint!,
            titleLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: backgroundSize)
        ])
    }

    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    @objc private func handleTap() {
        tappedHandler?()
    }

    // MARK: - Public Methods

    func setIcon(_ image: UIImage?) {
        iconButton.setImage(image?.withRenderingMode(.alwaysTemplate), for: [])
    }

    func setVisualState(isSelected: Bool, selectedIcon: UIImage?, normalIcon: UIImage?) {
        setIcon(isSelected ? selectedIcon : normalIcon)
        if isSelected {
            iconTintColor = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
            backgroundColour = Colours.actionIconBackground
            borderColor = nil
            borderWidth = 0
        } else {
            iconTintColor = Colours.actionIconForeground
            backgroundColour = Colours.actionIconBackground
            borderColor = nil
            borderWidth = 0
        }
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }

    func startProgressIndicator() {
        stopProgressIndicator()

        let progressCircle = CAShapeLayer()
        progressCircle.fillColor = UIColor.clear.cgColor
        progressCircle.strokeColor = Colours.orangePrimary.cgColor
        progressCircle.lineWidth = 3
        progressCircle.lineCap = .round
        progressCircle.strokeEnd = 0

        backgroundView.layer.addSublayer(progressCircle)
        progressLayer = progressCircle
        updateProgressLayerPath()
    }

    func updateProgress(_ progress: Float) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        progressLayer?.strokeEnd = CGFloat(max(0, min(1, progress)))
        CATransaction.commit()
    }

    func stopProgressIndicator() {
        progressLayer?.removeFromSuperlayer()
        progressLayer = nil
    }

    private func setShowsLabel(_ showLabel: Bool) {
        titleLabel.isHidden = !showLabel
        titleLabelTopConstraint?.isActive = true
        titleLabelBottomConstraint?.isActive = showLabel
        titleLabelCollapsedHeightConstraint?.isActive = !showLabel
        backgroundBottomConstraint?.isActive = !showLabel
    }

    private func updateProgressLayerPath() {
        guard let progressLayer else { return }

        let radius = backgroundSize / 2 - 4
        let center = CGPoint(x: backgroundView.bounds.midX, y: backgroundView.bounds.midY)
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 3 * .pi / 2,
            clockwise: true
        )
        progressLayer.path = path.cgPath
    }
}

// MARK: - Compact variant (no label, for use on book cards)

class CompactCircularIconButton: UIView {

    private let backgroundView = UIView()
    private let iconButton = UIButton(type: .system)
    private let progressLabel = UILabel()
    private var progressLayer: CAShapeLayer?

    var tappedHandler: (() -> Void)?

    var iconTintColor: UIColor = Colours.actionIconForeground {
        didSet {
            iconButton.tintColor = iconTintColor
            progressLabel.textColor = iconTintColor
        }
    }

    var backgroundColour: UIColor = Colours.actionIconBackground {
        didSet {
            backgroundView.backgroundColor = backgroundColour
        }
    }

    var borderColor: UIColor? = nil {
        didSet {
            backgroundView.layer.borderColor = borderColor?.cgColor
        }
    }

    var borderWidth: CGFloat = 0 {
        didSet {
            backgroundView.layer.borderWidth = borderWidth
        }
    }

    private let backgroundSize: CGFloat = 34
    private let iconSize: CGFloat = 16

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateProgressLayerPath()
    }

    private func setupViews() {
        setupBackgroundView()
        setupIconButton()
        setupProgressLabel()
        setupTapGesture()
    }

    private func setupBackgroundView() {
        backgroundView.backgroundColor = backgroundColour
        backgroundView.layer.cornerRadius = backgroundSize / 2
        backgroundView.layer.masksToBounds = true
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.widthAnchor.constraint(equalToConstant: backgroundSize),
            backgroundView.heightAnchor.constraint(equalToConstant: backgroundSize)
        ])
    }

    private func setupProgressLabel() {
        progressLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 9, weight: .semibold)
        progressLabel.textColor = iconTintColor
        progressLabel.textAlignment = .center
        progressLabel.adjustsFontSizeToFitWidth = true
        progressLabel.minimumScaleFactor = 0.65
        progressLabel.isHidden = true
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(progressLabel)

        NSLayoutConstraint.activate([
            progressLabel.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            progressLabel.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
            progressLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 5),
            progressLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -5)
        ])
    }

    private func setupIconButton() {
        iconButton.imageView?.contentMode = .scaleAspectFit
        iconButton.tintColor = iconTintColor
        iconButton.isUserInteractionEnabled = false
        iconButton.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(iconButton)

        NSLayoutConstraint.activate([
            iconButton.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            iconButton.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
            iconButton.widthAnchor.constraint(equalToConstant: iconSize),
            iconButton.heightAnchor.constraint(equalToConstant: iconSize)
        ])
    }

    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    @objc private func handleTap() {
        tappedHandler?()
    }

    func setIcon(_ image: UIImage?) {
        iconButton.setImage(image?.withRenderingMode(.alwaysTemplate), for: [])
    }

    func setVisualState(isSelected: Bool, selectedIcon: UIImage?, normalIcon: UIImage?) {
        stopProgressIndicator()
        setIcon(isSelected ? selectedIcon : normalIcon)
        iconButton.isHidden = false
        progressLabel.isHidden = true
        if isSelected {
            iconTintColor = UIColor.dynamic(light: Colours.themeAccentDark, dark: Colours.textPrimary)
            backgroundColour = Colours.actionIconBackground
            borderColor = nil
            borderWidth = 0
        } else {
            iconTintColor = Colours.actionIconForeground
            backgroundColour = Colours.actionIconBackground
            borderColor = nil
            borderWidth = 0
        }
    }

    func startProgressIndicator() {
        stopPulseAnimation()
        if progressLayer == nil {
            let progressCircle = CAShapeLayer()
            progressCircle.fillColor = UIColor.clear.cgColor
            progressCircle.strokeColor = Colours.orangePrimary.cgColor
            progressCircle.lineWidth = 2.5
            progressCircle.lineCap = .round
            progressCircle.strokeEnd = 0
            backgroundView.layer.addSublayer(progressCircle)
            progressLayer = progressCircle
            updateProgressLayerPath()
        }

        iconButton.isHidden = true
        progressLabel.isHidden = false
        updateProgress(0)
    }

    func updateProgress(_ progress: Float) {
        if progressLayer == nil {
            startProgressIndicator()
        }

        let clampedProgress = max(0, min(1, progress))
        let percentage = clampedProgress <= 0 ? 0 : max(1, min(99, Int(clampedProgress * 100)))

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        progressLayer?.strokeEnd = CGFloat(clampedProgress)
        CATransaction.commit()

        progressLabel.text = "\(percentage)%"
    }

    func stopProgressIndicator() {
        progressLayer?.removeFromSuperlayer()
        progressLayer = nil
        progressLabel.isHidden = true
        iconButton.isHidden = false
    }

    func startPulseAnimation() {
        let pulseAnimation = CABasicAnimation(keyPath: "opacity")
        pulseAnimation.duration = 0.8
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 0.3
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        layer.add(pulseAnimation, forKey: "pulseAnimation")
    }

    func stopPulseAnimation() {
        layer.removeAnimation(forKey: "pulseAnimation")
        layer.opacity = 1.0
    }

    private func updateProgressLayerPath() {
        guard let progressLayer else { return }

        let radius = backgroundSize / 2 - 3.5
        let center = CGPoint(x: backgroundView.bounds.midX, y: backgroundView.bounds.midY)
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 3 * .pi / 2,
            clockwise: true
        )
        progressLayer.path = path.cgPath
    }
}
