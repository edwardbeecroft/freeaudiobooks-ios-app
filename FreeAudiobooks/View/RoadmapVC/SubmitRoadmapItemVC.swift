//
//  SubmitRoadmapItemVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 06/03/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView

protocol SubmitRoadmapItemVCDelegate {
    func didSubmitNewRoadmapItem()
}

class SubmitRoadmapItemVC: BottomSheetController {

    var delegate: SubmitRoadmapItemVCDelegate?

    private var loadingIndicatorView: NVActivityIndicatorView?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.semiBold18
        label.textColor = Colours.textPrimary
        label.textAlignment = .center
        label.text = "Suggest a feature"
        return label
    }()

    private let requestFieldLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.medium12
        label.textColor = Colours.textSecondary
        label.text = "Your request"
        return label
    }()

    private let requestCharCountLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.medium12
        label.textColor = Colours.textSecondary
        label.textAlignment = .right
        label.text = "0/250"
        label.isHidden = true  // Initially hidden, shown at 150+ chars
        return label
    }()

    private lazy var requestTextView: UITextView = {
        let textView = UITextView()
        textView.font = Fonts.regular15
        textView.textColor = Colours.textPrimary
        textView.backgroundColor = Colours.inputBackground
        textView.layer.cornerRadius = UIConstants.shared.cardCornerRadius
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.isScrollEnabled = true
        textView.autocorrectionType = .yes
        textView.returnKeyType = .send
        textView.delegate = self
        return textView
    }()

    private lazy var typewriterPlaceholder: TypewriterTextView = {
        let textView = TypewriterTextView(letterInterval: 0.05, letterUnwindInterval: 0.02, insetText: true)
        textView.font = Fonts.regular15
        textView.textColor = .placeholderText
        textView.backgroundColor = .clear
        textView.isUserInteractionEnabled = false
        return textView
    }()

    private lazy var staticPlaceholder: UILabel = {
        let label = UILabel()
        label.font = Fonts.regular15
        label.textColor = .placeholderText
        label.text = placeholderSuggestions.first
        label.numberOfLines = 0
        return label
    }()

    private let placeholderSuggestions = [
        "I'd like to filter books by author...",
        "Dark mode would make listening easier at night...",
        "It would be great if I could bookmark favorite quotes...",
        "The ability to share book recommendations with friends...",
        "Better search with filters for genre and length...",
        "I wish I could see my listening stats and progress...",
        "A feature to organize books into custom collections...",
        "Offline listening mode for when I'm traveling..."
    ]
    private var currentPlaceholderIndex = 0

    private let helperLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.medium13
        label.textColor = Colours.textSecondary
        label.textAlignment = .center
        label.text = "One sentence is perfect. We’ll ask if we need more."
        return label
    }()

    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = Colours.separator
        return view
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = Colours.textSecondary
        button.backgroundColor = Colours.surfaceSecondary
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return button
    }()

    private lazy var submitButton: UIButton = {
        let button = Buttons.primaryCTA(buttonTitle: "Send")
        button.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        return button
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
        preferredSheetSizing = .fit
        preferredSheetCornerRadius = 16
        tapToDismissEnabled = false
        panToDismissEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colours.surfacePrimary
        setupLayout()
        hideKeyboardWhenTappedAround()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupKeyboardObservers()
        setupPlaceholders()
    }

    private func setupPlaceholders() {
        let variant = RoadmapInputVariant.current

        switch variant {
        case .typewriter:
            staticPlaceholder.isHidden = true
            typewriterPlaceholder.isHidden = false
            if requestTextView.text.isEmpty {
                startPlaceholderCycle()
            }
        case .static:
            typewriterPlaceholder.isHidden = true
            staticPlaceholder.isHidden = false
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardObservers()
        typewriterPlaceholder.cancelAllTypingAnimations()
    }
}

// MARK: - Layout
private extension SubmitRoadmapItemVC {
    func setupLayout() {
        let margin = UIConstants.shared.standardMargin

        view.addSubviewForConstraints(titleLabel)
        view.addSubviewForConstraints(closeButton)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        view.addSubviewForConstraints(dividerView)
        NSLayoutConstraint.activate([
            dividerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            dividerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            dividerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            dividerView.heightAnchor.constraint(equalToConstant: 1)
        ])

        view.addSubviewForConstraints(requestFieldLabel)
        view.addSubviewForConstraints(requestCharCountLabel)
        NSLayoutConstraint.activate([
            requestFieldLabel.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: 24),
            requestFieldLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),

            requestCharCountLabel.centerYAnchor.constraint(equalTo: requestFieldLabel.centerYAnchor),
            requestCharCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin)
        ])

        view.addSubviewForConstraints(requestTextView)
        NSLayoutConstraint.activate([
            requestTextView.topAnchor.constraint(equalTo: requestFieldLabel.bottomAnchor, constant: 6),
            requestTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            requestTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            requestTextView.heightAnchor.constraint(equalToConstant: 110)
        ])

        view.addSubviewForConstraints(typewriterPlaceholder)
        NSLayoutConstraint.activate([
            typewriterPlaceholder.topAnchor.constraint(equalTo: requestTextView.topAnchor, constant: 12),
            typewriterPlaceholder.leadingAnchor.constraint(equalTo: requestTextView.leadingAnchor, constant: 5),
            typewriterPlaceholder.trailingAnchor.constraint(equalTo: requestTextView.trailingAnchor, constant: -13),
            typewriterPlaceholder.bottomAnchor.constraint(lessThanOrEqualTo: requestTextView.bottomAnchor, constant: -12)
        ])

        view.addSubviewForConstraints(staticPlaceholder)
        NSLayoutConstraint.activate([
            staticPlaceholder.topAnchor.constraint(equalTo: requestTextView.topAnchor, constant: 12),
            staticPlaceholder.leadingAnchor.constraint(equalTo: requestTextView.leadingAnchor, constant: 13),
            staticPlaceholder.trailingAnchor.constraint(equalTo: requestTextView.trailingAnchor, constant: -13)
        ])

        view.addSubviewForConstraints(helperLabel)
        NSLayoutConstraint.activate([
            helperLabel.topAnchor.constraint(equalTo: requestTextView.bottomAnchor, constant: 20),
            helperLabel.leadingAnchor.constraint(equalTo: requestTextView.leadingAnchor),
            helperLabel.trailingAnchor.constraint(equalTo: requestTextView.trailingAnchor)
        ])

        view.addSubviewForConstraints(submitButton)
        NSLayoutConstraint.activate([
            submitButton.topAnchor.constraint(equalTo: helperLabel.bottomAnchor, constant: margin),
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            submitButton.heightAnchor.constraint(equalToConstant: 50),
            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -margin)
        ])
    }
}

// MARK: - UITextViewDelegate
extension SubmitRoadmapItemVC: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let count = textView.text.count
        requestCharCountLabel.text = "\(count)/250"

        // Only show counter when approaching limit (150+ chars)
        requestCharCountLabel.isHidden = count < 150

        // Handle placeholder visibility based on variant
        let variant = RoadmapInputVariant.current
        switch variant {
        case .typewriter:
            if textView.text.isEmpty {
                typewriterPlaceholder.isHidden = false
                startPlaceholderCycle()
            } else {
                typewriterPlaceholder.isHidden = true
                typewriterPlaceholder.cancelAllTypingAnimations()
            }
        case .static:
            staticPlaceholder.isHidden = !textView.text.isEmpty
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            submitTapped()
            return false
        }
        let current = textView.text ?? ""
        guard let range = Range(range, in: current) else { return false }
        let updated = current.replacingCharacters(in: range, with: text)
        return updated.count <= 250
    }
}

// MARK: - Actions
extension SubmitRoadmapItemVC {
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - Submission
extension SubmitRoadmapItemVC {
    @objc private func submitTapped() {
        let request = requestTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !request.isEmpty else {
            showAlertForEmptyTextField()
            return
        }

        showLoadingIndicator(show: true)

        RoadmapManager.shared.uploadNewRoadmapItem(title: request) { [weak self] success in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.showLoadingIndicator(show: false)
                guard success else {
                    self.showGenericError()
                    return
                }
                AnalyticsManager.shared.trackRoadmapItemSubmitted()
                self.delegate?.didSubmitNewRoadmapItem()
            }
        }
    }

    private func showGenericError() {
        let title = L10n.networkError
        let message = "Please check your connection and try again."

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let retryAction = UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.submitTapped()
            }
        }

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        self.present(alertController, animated: true, completion: nil)
    }

    private func showAlertForEmptyTextField() {
        let alert = UIAlertController(title: "Input Required",
                                      message: "Please describe your request.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}

// MARK: - Keyboard
private extension SubmitRoadmapItemVC {
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        let keyboardHeight = keyboardFrame.height
        UIView.animate(withDuration: duration) {
            self.view.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight + self.view.safeAreaInsets.bottom)
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        UIView.animate(withDuration: duration) {
            self.view.transform = .identity
        }
    }
}

// MARK: - Loading Indicator
private extension SubmitRoadmapItemVC {
    func showLoadingIndicator(show: Bool) {
        if show {
            guard loadingIndicatorView == nil else { return }
            submitButton.isHidden = true

            loadingIndicatorView = NVActivityIndicatorView(frame: .zero, type: .circleStrokeSpin, color: Colours.textPrimary, padding: 0)
            guard let indicatorView = loadingIndicatorView else { return }

            view.addSubviewForConstraints(indicatorView)
            NSLayoutConstraint.activate([
                indicatorView.centerYAnchor.constraint(equalTo: submitButton.centerYAnchor),
                indicatorView.centerXAnchor.constraint(equalTo: submitButton.centerXAnchor),
                indicatorView.widthAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
                indicatorView.heightAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight)
            ])
            indicatorView.startAnimating()
        } else {
            loadingIndicatorView?.stopAnimating()
            loadingIndicatorView?.removeFromSuperview()
            loadingIndicatorView = nil
            submitButton.isHidden = false
        }
    }
}

// MARK: - Placeholder Animation
private extension SubmitRoadmapItemVC {
    func startPlaceholderCycle() {
        animateNextPlaceholder()
    }

    func animateNextPlaceholder() {
        let suggestion = placeholderSuggestions[currentPlaceholderIndex]

        typewriterPlaceholder.animateTyping(
            suggestionText: suggestion,
            includeUnderscore: true,
            selfSize: false,
            selfSizeSideInsets: 0,
            completion: { [weak self] in
                guard let self = self else { return }
                // Wait a moment, then unwind
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.unwindAndCycleToNext()
                }
            },
            letterCompletion: nil
        )
    }

    func unwindAndCycleToNext() {
        typewriterPlaceholder.unwindText { [weak self] in
            guard let self = self else { return }
            // Move to next suggestion
            self.currentPlaceholderIndex = (self.currentPlaceholderIndex + 1) % self.placeholderSuggestions.count

            // Wait a moment, then animate next
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Only continue cycling if text field is still empty
                if self.requestTextView.text.isEmpty {
                    self.animateNextPlaceholder()
                }
            }
        }
    }
}
