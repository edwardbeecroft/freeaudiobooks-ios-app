//
//  FilterChipView.swift
//  FreeAudiobooks
//
//  Created by Assistant on 01/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

struct FilterChip {
    enum ChipType {
        case query
        case genre
        case readingTime
        case format
        case rating
        case adult
        case sort

        var color: UIColor {
            switch self {
            case .query: return Colours.themeAccentDark
            case .genre: return Colours.orangePrimary
            case .readingTime: return UIColor.systemBlue
            case .format: return UIColor.systemPurple
            case .rating: return UIColor.systemOrange
            case .adult: return UIColor.systemPink
            case .sort: return UIColor.systemGreen
            }
        }
    }

    let id: String
    let label: String
    let type: ChipType
}

class FilterChipView: UIView {
    
    private let label = UILabel()
    private let closeButton = UIButton(type: .system)
    private var chip: FilterChip?
    var onRemove: ((String) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        layer.cornerRadius = 14
        layer.masksToBounds = true
        
        label.font = Fonts.medium13
        label.textColor = .white
        addSubviewForConstraints(label)
        
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white.withAlphaComponent(0.9)
        closeButton.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)
        addSubviewForConstraints(closeButton)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            closeButton.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 4),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 16),
            closeButton.heightAnchor.constraint(equalToConstant: 16),
            
            heightAnchor.constraint(equalToConstant: 28)
        ])
    }
    
    func configure(with chip: FilterChip) {
        self.chip = chip
        label.text = chip.label
        backgroundColor = chip.type.color.withAlphaComponent(0.9)
    }
    
    @objc private func removeTapped() {
        guard let chip = chip else { return }
        onRemove?(chip.id)
    }
}
