//
//  ReadingConfigPreferencesVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 08/08/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

final class ReadingConfigPreferencesVC: BottomSheetController {

    var dismissHandler: (() -> Void)?
    var resetHandler: (() -> Void)?
    var applyHandler: (() -> Void)?
    var selectFontHandler: ((_ font: ReadingFont) -> Void)?
    var selectTextSizeHandler: ((_ textSize: ReadingTextSize) -> Void)?
    var selectThemeHandler: ((_ theme: ReadingTheme) -> Void)?
    var selectParagraphStyleHandler: ((_ paragraphStyle: ReadingParagraphStyle) -> Void)?

    private let fontStackView = UIStackView()
    private let textSizeStackView = UIStackView()
    private let themeStackView = UIStackView()
    private let paragraphStyleStackView = UIStackView()

    // Track current selections for border updates
    private var currentTheme: ReadingTheme
    private var currentFont: ReadingFont
    private var currentTextSize: ReadingTextSize
    private var currentParagraphStyle: ReadingParagraphStyle

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        // Initialize with current UserDefaults values
        self.currentTheme = ReadingUserDefaults.theme
        self.currentFont = ReadingUserDefaults.font
        self.currentTextSize = ReadingUserDefaults.textSize
        self.currentParagraphStyle = ReadingUserDefaults.paragraphStyle
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        // Initialize with current UserDefaults values
        self.currentTheme = ReadingUserDefaults.theme
        self.currentFont = ReadingUserDefaults.font
        self.currentTextSize = ReadingUserDefaults.textSize
        self.currentParagraphStyle = ReadingUserDefaults.paragraphStyle
        super.init(coder: coder)
    }
    
    override func loadView() {
        view = UIView()
        
        let titleLabel = UILabel()
        titleLabel.font = Fonts.semiBold16
        titleLabel.textColor = Colours.textPrimary
        titleLabel.text = "Reading Preferences"
        titleLabel.textAlignment = .center
        
        let borderView = SplitterView()
        NSLayoutConstraint.activate([
//            borderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
//            borderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            borderView.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        let fontHeadingLabel = UILabel()
        let textSizeLabel = UILabel()
        let backgroundColorLabel = UILabel()
        let paragraphStyleLabel = UILabel()

        [fontHeadingLabel, textSizeLabel, backgroundColorLabel, paragraphStyleLabel].forEach { label in
            label.font = Fonts.semiBold15
            label.textColor = Colours.textPrimary
            label.textAlignment = .left
        }
        fontHeadingLabel.text = "Font"
        textSizeLabel.text = "Text Size"
        backgroundColorLabel.text = "Theme"
        paragraphStyleLabel.text = "Paragraphs"
        
        [fontStackView, textSizeStackView, themeStackView, paragraphStyleStackView].forEach { stackView in
            stackView.axis = .horizontal
            stackView.distribution = .fillEqually
            stackView.alignment = .center
            stackView.spacing = 6
        }
        
        ReadingTheme.allCases.forEach { theme in
            let themeView = ThemeView(theme: theme)
            themeView.tappedThemeHandler = { [weak self] in
                guard let self else { return }
                self.currentTheme = theme
                self.selectThemeHandler?(theme)
                self.updateThemeViews()
            }
            themeStackView.addArrangedSubview(themeView)
        }
        
        ReadingFont.allCases.forEach { font in
            let fontView = FontView(font: font)
            fontView.tappedFontHandler = { [weak self] in
                guard let self else { return }
                self.currentFont = font
                self.selectFontHandler?(font)
                self.updateThemeViews()
            }
            fontStackView.addArrangedSubview(fontView)
        }
        
        ReadingTextSize.allCases.forEach { textSize in
            let textSizeView = TextSizeView(textSize: textSize)
            textSizeView.tappedTextSizeHandler = { [weak self] in
                guard let self else { return }
                self.currentTextSize = textSize
                self.selectTextSizeHandler?(textSize)
                self.updateThemeViews()
            }
            textSizeStackView.addArrangedSubview(textSizeView)
        }

        ReadingParagraphStyle.allCases.forEach { style in
            let styleView = ParagraphStyleView(paragraphStyle: style)
            styleView.tappedHandler = { [weak self] in
                guard let self else { return }
                self.currentParagraphStyle = style
                self.selectParagraphStyleHandler?(style)
                self.updateThemeViews()
            }
            paragraphStyleStackView.addArrangedSubview(styleView)
        }

        let applyButton = Buttons.primaryCTA(buttonTitle: "Apply")
        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)

        let bottomBorderView = SplitterView()
        NSLayoutConstraint.activate([
//            borderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
//            borderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            bottomBorderView.heightAnchor.constraint(equalToConstant: 1)
        ])

        // Wrap apply button in container to center it
        let applyButtonContainer = UIView()
        applyButtonContainer.addSubviewForConstraints(applyButton)
        NSLayoutConstraint.activate([
            applyButtonContainer.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight),
            applyButton.centerXAnchor.constraint(equalTo: applyButtonContainer.centerXAnchor),
            applyButton.centerYAnchor.constraint(equalTo: applyButtonContainer.centerYAnchor),
            applyButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight),
            applyButton.widthAnchor.constraint(equalTo: applyButtonContainer.widthAnchor, multiplier: 0.8)
        ])

        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            borderView,
            fontHeadingLabel,
            fontStackView,
            textSizeLabel,
            textSizeStackView,
            backgroundColorLabel,
            themeStackView,
            paragraphStyleLabel,
            paragraphStyleStackView,
            bottomBorderView,
            applyButtonContainer
        ])
        
        // Add a spacer view for iPad screenshots so we can see the full UI
        if AppConstants.shared.developmentMode == .screenshots && UIDevice().iPad {
            let spacerView = UIView()
            spacerView.translatesAutoresizingMaskIntoConstraints = false
            spacerView.heightAnchor.constraint(equalToConstant: 102).isActive = true
            stackView.addArrangedSubview(spacerView)
        }
        
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 20
        stackView.setCustomSpacing(20, after: titleLabel)
        stackView.setCustomSpacing(20, after: borderView)
        [fontHeadingLabel, textSizeLabel, backgroundColorLabel, paragraphStyleLabel].forEach { label in
            stackView.setCustomSpacing(8, after: label)
        }
        stackView.setCustomSpacing(20, after: paragraphStyleStackView)
        
        view.addSubviewForConstraints(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -16)
        ])

        view.backgroundColor = Colours.surfacePrimary
        
        let resetButton = UIButton()
        resetButton.setImage(UIImage(named: "reset")?.withRenderingMode(.alwaysTemplate), for: [])
        resetButton.tintColor = Colours.textSecondary
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        view.addSubviewForConstraints(resetButton)
        NSLayoutConstraint.activate([
            resetButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            resetButton.heightAnchor.constraint(equalToConstant: 22),
            resetButton.widthAnchor.constraint(equalToConstant: 22),
            resetButton.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: UIConstants.shared.standardMargin)
        ])
        
        let dismissButton = UIButton()
        dismissButton.setImage(UIImage(named: "dismissIcon")?.withRenderingMode(.alwaysTemplate), for: [])
        dismissButton.tintColor = Colours.textSecondary
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        view.addSubviewForConstraints(dismissButton)
        NSLayoutConstraint.activate([
            dismissButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            dismissButton.heightAnchor.constraint(equalToConstant: 32),
            dismissButton.widthAnchor.constraint(equalToConstant: 32),
            dismissButton.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -UIConstants.shared.standardMargin)
        ])
    }
    
    @objc func dismissTapped() {
        dismissHandler?()
    }
    @objc func resetTapped() {
        resetHandler?()
    }
    @objc func applyTapped() {
        applyHandler?()
    }
}

extension ReadingConfigPreferencesVC {
    func updateThemeViews() {
        for subview in themeStackView.arrangedSubviews {
            if let themeView = subview as? ThemeView {
                themeView.update(selectedTheme: currentTheme)
            }
        }
        for subview in fontStackView.arrangedSubviews {
            if let fontView = subview as? FontView {
                fontView.update(selectedFont: currentFont)
            }
        }
        for subview in textSizeStackView.arrangedSubviews {
            if let textSizeView = subview as? TextSizeView {
                textSizeView.update(selectedTextSize: currentTextSize)
            }
        }
        for subview in paragraphStyleStackView.arrangedSubviews {
            if let styleView = subview as? ParagraphStyleView {
                styleView.update(selectedParagraphStyle: currentParagraphStyle)
            }
        }
    }
}
