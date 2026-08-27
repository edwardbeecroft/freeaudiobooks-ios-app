import UIKit

final class PushPrePromptVC: BottomSheetController {

    var enableHandler: (() -> Void)?
    var dismissHandler: (() -> Void)?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.preferredSheetSizing = .fit
        self.tapToDismissEnabled = false
        self.panToDismissEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground

        // Title
        let titleLabel = UILabel()
        titleLabel.font = Fonts.semiBold18
        titleLabel.textColor = Colours.textPrimary
        titleLabel.text = RCValues.shared.string(forKey: .pushPrePromptTitleAB)
        titleLabel.textAlignment = .center

        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.font = Fonts.medium15
        subtitleLabel.textColor = Colours.textSecondary
        subtitleLabel.text = RCValues.shared.string(forKey: .pushPrePromptSubtitleAB)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        // Subtitle container with additional side insets
        let subtitleContainer = UIView()
        subtitleContainer.addSubviewForConstraints(subtitleLabel)
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: subtitleContainer.topAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: subtitleContainer.bottomAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: subtitleContainer.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: subtitleContainer.trailingAnchor, constant: -40)
        ])

        // Enable button (primary)
        let enableButton = Buttons.primaryCTA(buttonTitle: RCValues.shared.string(forKey: .pushPrePromptEnableCTA))
        enableButton.addTarget(self, action: #selector(enableTapped), for: .touchUpInside)

        // Not now button (secondary)
        let notNowButton = UIButton(type: .system)
        notNowButton.setTitle(RCValues.shared.string(forKey: .pushPrePromptNotNowCTA), for: .normal)
        notNowButton.titleLabel?.font = Fonts.medium15
        notNowButton.setTitleColor(Colours.negativeButtonTitle, for: [])

        notNowButton.addTarget(self, action: #selector(notNowTapped), for: .touchUpInside)

        // Button container
        let buttonContainer = UIView()
        buttonContainer.addSubviewForConstraints(enableButton)
        NSLayoutConstraint.activate([
            enableButton.centerXAnchor.constraint(equalTo: buttonContainer.centerXAnchor),
            enableButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            enableButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight),
            enableButton.widthAnchor.constraint(equalTo: buttonContainer.widthAnchor)
        ])

        // Stack view
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleContainer,
            buttonContainer,
            notNowButton
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 20
        stackView.setCustomSpacing(8, after: titleLabel)
        stackView.setCustomSpacing(24, after: subtitleContainer)
        stackView.setCustomSpacing(12, after: buttonContainer)

        view.addSubviewForConstraints(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            buttonContainer.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight)
        ])
    }

    @objc private func enableTapped() {
        enableHandler?()
    }

    @objc private func notNowTapped() {
        dismissHandler?()
    }
}
