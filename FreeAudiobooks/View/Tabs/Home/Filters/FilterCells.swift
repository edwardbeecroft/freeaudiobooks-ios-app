//
//  FilterCells.swift
//  FreeAudiobooks
//
//  Created by Assistant on 01/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import BetterSegmentedControl

// MARK: - FilterTextFieldCell

class FilterTextFieldCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let textField = UITextField()
    var onTextChanged: ((String) -> Void)?
    var onTapped: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateAppearanceColors()
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .systemBackground
        contentView.backgroundColor = Colours.surfacePrimary
        
        titleLabel.font = Fonts.medium15
        titleLabel.textColor = Colours.textPrimary
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        contentView.addSubviewForConstraints(titleLabel)
        
        textField.font = Fonts.medium15
        textField.textColor = Colours.textPrimary
        textField.borderStyle = .none
        textField.backgroundColor = Colours.inputBackground
        textField.layer.cornerRadius = UIConstants.shared.cornerRadius
        textField.layer.borderWidth = 1
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        textField.leftViewMode = .always
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.delegate = self
        
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        contentView.addSubviewForConstraints(textField)
        updateAppearanceColors()
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            textField.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            textField.heightAnchor.constraint(equalToConstant: 36),
            textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(title: String, placeholder: String, value: String?, isSelectable: Bool = false) {
        titleLabel.text = title
        textField.placeholder = placeholder
        textField.text = value
        
        if isSelectable {
            textField.isUserInteractionEnabled = false
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
            contentView.addGestureRecognizer(tapGesture)
            
            let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
            chevronImageView.tintColor = Colours.grey140
            chevronImageView.contentMode = .scaleAspectFit

            // Wrap in a container with padding
            let container = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            chevronImageView.frame = CGRect(x: 0, y: 0, width: 10, height: 20)
            chevronImageView.center.y = container.center.y
            container.addSubview(chevronImageView)

            textField.rightView = container
            textField.rightViewMode = .always
        } else {
            textField.isUserInteractionEnabled = true
            contentView.gestureRecognizers?.removeAll()
            textField.rightView = nil
        }
    }
    
    @objc private func textChanged() {
        onTextChanged?(textField.text ?? "")
    }
    
    @objc private func cellTapped() {
        onTapped?()
    }

    private func updateAppearanceColors() {
        textField.layer.borderColor = Colours.inputBorder.cgColor
    }
}

extension FilterTextFieldCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        return false
    }
}

// MARK: - FilterSegmentedCell

class FilterSegmentedCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let segmentedControl = BetterSegmentedControl()
    var onSelectionChanged: ((Int) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .systemBackground
        
        titleLabel.font = Fonts.medium15
        titleLabel.textColor = Colours.textPrimary
        contentView.addSubviewForConstraints(titleLabel)
        
        segmentedControl.addTarget(self, action: #selector(selectionChanged), for: .valueChanged)
        contentView.addSubviewForConstraints(segmentedControl)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            
            segmentedControl.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            segmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            segmentedControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        let options: [BetterSegmentedControl.Option] = [.backgroundColor(Colours.themeAccentDark),
                                                        .indicatorViewBackgroundColor(.white),
                                                        .cornerRadius(4.0),
                                                        .animationSpringDamping(1.0)]
        segmentedControl.setOptions(options)
    }
    
    func configure(title: String, options: [String], selectedIndex: Int) {
        titleLabel.text = title
        segmentedControl.segments.removeAll()
        segmentedControl.segments = LabelSegment.segments(withTitles: options,
                                                          normalFont: Fonts.medium15,
                                                          normalTextColor: .white,
                                                          selectedFont:Fonts.medium15,
                                                          selectedTextColor: Colours.themeAccentDark)
        segmentedControl.setIndex(selectedIndex)
    }
    
    @objc private func selectionChanged() {
        onSelectionChanged?(segmentedControl.index)
    }
}

// MARK: - FilterRangeSliderCell

class FilterRangeSliderCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let minTitleLabel = UILabel()
    private let maxTitleLabel = UILabel()
    private let minLabel = UILabel()
    private let maxLabel = UILabel()
    private let minSlider = UISlider()
    private let maxSlider = UISlider()
    private let rangeView = UIView()
    
    var onRangeChanged: ((Float, Float) -> Void)?
    private var formatter: ((Float) -> String)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .systemBackground
        
        titleLabel.font = Fonts.medium15
        titleLabel.textColor = Colours.textPrimary
        contentView.addSubviewForConstraints(titleLabel)
        
        minTitleLabel.font = Fonts.medium12
        minTitleLabel.textColor = Colours.textSecondary
        minTitleLabel.text = "Min"
        minTitleLabel.textAlignment = .left
        contentView.addSubviewForConstraints(minTitleLabel)
        
        maxTitleLabel.font = Fonts.medium12
        maxTitleLabel.textColor = Colours.textSecondary
        maxTitleLabel.text = "Max"
        maxTitleLabel.textAlignment = .right
        contentView.addSubviewForConstraints(maxTitleLabel)
        
        minLabel.font = Fonts.medium13
        minLabel.textColor = Colours.textSecondary
        minLabel.textAlignment = .left
        contentView.addSubviewForConstraints(minLabel)
        
        maxLabel.font = Fonts.medium13
        maxLabel.textColor = Colours.textSecondary
        maxLabel.textAlignment = .right
        contentView.addSubviewForConstraints(maxLabel)
        
        rangeView.backgroundColor = Colours.inputBorder
        rangeView.layer.cornerRadius = 2
        contentView.addSubviewForConstraints(rangeView)
        
        minSlider.tintColor = Colours.themeAccentDark
        minSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        contentView.addSubviewForConstraints(minSlider)
        
        maxSlider.tintColor = Colours.themeAccentDark
        maxSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        contentView.addSubviewForConstraints(maxSlider)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            minTitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            minTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            
            maxTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            maxTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            
            minLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            minLabel.topAnchor.constraint(equalTo: minTitleLabel.bottomAnchor, constant: 2),
            
            maxLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            maxLabel.topAnchor.constraint(equalTo: maxTitleLabel.bottomAnchor, constant: 2),
            
            rangeView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            rangeView.trailingAnchor.constraint(equalTo: maxLabel.trailingAnchor),
            rangeView.topAnchor.constraint(equalTo: minLabel.bottomAnchor, constant: 16),
            rangeView.heightAnchor.constraint(equalToConstant: 4),
            
            minSlider.leadingAnchor.constraint(equalTo: rangeView.leadingAnchor),
            minSlider.trailingAnchor.constraint(equalTo: rangeView.centerXAnchor),
            minSlider.centerYAnchor.constraint(equalTo: rangeView.centerYAnchor),
            
            maxSlider.leadingAnchor.constraint(equalTo: rangeView.centerXAnchor),
            maxSlider.trailingAnchor.constraint(equalTo: rangeView.trailingAnchor),
            maxSlider.centerYAnchor.constraint(equalTo: rangeView.centerYAnchor),
            
            rangeView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    func configure(title: String, minValue: Float, maxValue: Float, currentMin: Float, currentMax: Float, formatter: @escaping (Float) -> String) {
        titleLabel.text = title
        self.formatter = formatter
        
        minSlider.minimumValue = minValue
        minSlider.maximumValue = maxValue
        minSlider.value = currentMin
        
        maxSlider.minimumValue = minValue
        maxSlider.maximumValue = maxValue
        maxSlider.value = currentMax
        
        updateLabels()
    }
    
    @objc private func sliderChanged() {
        // Ensure min doesn't exceed max
        if minSlider.value > maxSlider.value {
            if minSlider.isTracking {
                maxSlider.value = minSlider.value
            } else {
                minSlider.value = maxSlider.value
            }
        }
        
        updateLabels()
        onRangeChanged?(minSlider.value, maxSlider.value)
    }
    
    private func updateLabels() {
        let formatter = self.formatter ?? { "\(Int($0))" }
        minLabel.text = formatter(minSlider.value)
        maxLabel.text = formatter(maxSlider.value)
    }
}

// MARK: - FilterSwitchCell

class FilterSwitchCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let switchControl = UISwitch()
    var onSwitchToggled: ((Bool) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .systemBackground
        
        titleLabel.font = Fonts.medium16
        titleLabel.textColor = Colours.textPrimary
        contentView.addSubviewForConstraints(titleLabel)
        
        switchControl.onTintColor = Colours.themeAccentDark
        switchControl.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
        contentView.addSubviewForConstraints(switchControl)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            switchControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            switchControl.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(title: String, isOn: Bool) {
        titleLabel.text = title
        switchControl.isOn = isOn
    }
    
    @objc private func switchToggled() {
        onSwitchToggled?(switchControl.isOn)
    }
}
