//
//  BuildsHabitsLineChartVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 26/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// Builds habits line chart screen
/// Comparison chart showing FreeAudiobooks vs trying alone over 30 days
class BuildsHabitsLineChartVC: BaseNewOnboardingVC {

    override var step: NewOnboardingStep { .buildsHabitsLineChart }

    // MARK: - UI Elements

    private let headlineLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = Colours.textPrimary
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    private let chartView: HabitComparisonChartView = {
        let view = HabitComparisonChartView()
        view.backgroundColor = .clear
        return view
    }()

    private let metricLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.medium18
        label.textColor = Colours.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let footnoteLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.medium13
        label.textColor = Colours.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        // Set text from RemoteConfig
        headlineLabel.text = RCValues.shared.string(forKey: .onbBuildsHabitsTitleAB)
        metricLabel.text = RCValues.shared.string(forKey: .onbBuildsHabitsMetricAB)
        footnoteLabel.text = RCValues.shared.string(forKey: .onbBuildsHabitsFootnoteAB)

        // Configure chart
        chartView.chartTitle = RCValues.shared.string(forKey: .onbBuildsHabitsChartLabelAB)
        chartView.freebooksLabel = RCValues.shared.string(forKey: .onbBuildsHabitsFreeAudiobooksAB)
        chartView.tryingAloneLabel = RCValues.shared.string(forKey: .onbBuildsHabitsTryingAlone)

        // Headline pinned to top
        contentView.addSubviewForConstraints(headlineLabel)

        // Chart + labels in a stack, centered in remaining space
        let chartStack = UIStackView(arrangedSubviews: [chartView, metricLabel, footnoteLabel])
        chartStack.axis = .vertical
        chartStack.spacing = 12
        chartStack.alignment = .fill
        chartStack.setCustomSpacing(32, after: chartView)

        contentView.addSubviewForConstraints(chartStack)

        // Layout guide for the space below headline
        let remainingSpaceGuide = UILayoutGuide()
        contentView.addLayoutGuide(remainingSpaceGuide)

        NSLayoutConstraint.activate([
            // Headline at top
            headlineLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headlineLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headlineLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            // Remaining space guide spans from headline bottom to contentView bottom
            remainingSpaceGuide.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor),
            remainingSpaceGuide.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            remainingSpaceGuide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            remainingSpaceGuide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Chart stack centered within remaining space
            chartStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            chartStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            chartStack.centerYAnchor.constraint(equalTo: remainingSpaceGuide.centerYAnchor)
        ])
    }
}
