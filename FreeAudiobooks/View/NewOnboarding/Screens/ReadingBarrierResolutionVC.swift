//
//  ReadingBarrierResolutionVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 27/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

/// Personalized stat screen that adapts based on user's primary reading barrier
/// Shows different visuals and copy for: lack_of_time, too_many_choices, hard_to_stay_motivated
class ReadingBarrierResolutionVC: BaseNewOnboardingVC {

    override var step: NewOnboardingStep { .readingBarrierResolution }

    // MARK: - Barrier Variant

    private var currentVariant: ReadingBarrier {
        let barriers = coordinator.dataStore.readingBarriers
        if
            let firstBarrier = barriers.first,
            let barrier = ReadingBarrier(rawValue: firstBarrier) {
            return barrier
        }
        return .lackOfTime // fallback
    }

    // MARK: - UI Elements

    private let headlineLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        label.textColor = Colours.textPrimary
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    private var visualContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let statLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.medium18
        label.textColor = Colours.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureForVariant()
    }

    // MARK: - Setup

    private func setupUI() {
        // Create remaining space guide for centering content
        let remainingSpaceGuide = UILayoutGuide()
        contentView.addLayoutGuide(remainingSpaceGuide)

        contentView.addSubviewForConstraints(headlineLabel)
        contentView.addSubview(visualContainerView)
        contentView.addSubviewForConstraints(statLabel)

        // Main container stack for visual + labels
        let contentStack = UIStackView(arrangedSubviews: [visualContainerView, statLabel])
        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            // Headline at top
            headlineLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headlineLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headlineLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            // Remaining space guide between headline and bottom
            remainingSpaceGuide.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor),
            remainingSpaceGuide.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            remainingSpaceGuide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            remainingSpaceGuide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Content stack centered in remaining space
            contentStack.centerYAnchor.constraint(equalTo: remainingSpaceGuide.centerYAnchor),
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }

    private func configureForVariant() {
        switch currentVariant {
        case .lackOfTime:
            configureForLackOfTime()
        case .tooManyChoices:
            configureForTooManyChoices()
        case .hardToStayMotivated:
            configureForHardToStayMotivated()
        }
    }

    // MARK: - Variant Configurations

    private func configureForLackOfTime() {
        headlineLabel.text = RCValues.shared.string(forKey: .onbMakeTimeHeadlineLackOfTimeAB)
        statLabel.text = RCValues.shared.string(forKey: .onbMakeTimeStatLackOfTimeAB)

        let dayTimelineView = DayTimelineView()
        dayTimelineView.translatesAutoresizingMaskIntoConstraints = false
        visualContainerView.addSubview(dayTimelineView)

        NSLayoutConstraint.activate([
            dayTimelineView.topAnchor.constraint(equalTo: visualContainerView.topAnchor),
            dayTimelineView.leadingAnchor.constraint(equalTo: visualContainerView.leadingAnchor),
            dayTimelineView.trailingAnchor.constraint(equalTo: visualContainerView.trailingAnchor),
            dayTimelineView.bottomAnchor.constraint(equalTo: visualContainerView.bottomAnchor)
        ])
    }

    private func configureForTooManyChoices() {
        headlineLabel.text = RCValues.shared.string(forKey: .onbMakeTimeHeadlineTooManyChoicesAB)
        statLabel.text = RCValues.shared.string(forKey: .onbMakeTimeStatTooManyChoicesAB)

        let primaryGenre = coordinator.dataStore.selectedGenres.first
        let bookPicksView = BookPicksView(primaryGenre: primaryGenre)
        bookPicksView.translatesAutoresizingMaskIntoConstraints = false
        visualContainerView.addSubview(bookPicksView)

        NSLayoutConstraint.activate([
            bookPicksView.topAnchor.constraint(equalTo: visualContainerView.topAnchor),
            bookPicksView.leadingAnchor.constraint(equalTo: visualContainerView.leadingAnchor),
            bookPicksView.trailingAnchor.constraint(equalTo: visualContainerView.trailingAnchor),
            bookPicksView.bottomAnchor.constraint(equalTo: visualContainerView.bottomAnchor)
        ])
    }

    private func configureForHardToStayMotivated() {
        headlineLabel.text = RCValues.shared.string(forKey: .onbMakeTimeHeadlineHardToStay)
        statLabel.text = RCValues.shared.string(forKey: .onbMakeTimeStatHardToStayAB)

        let streakProgressView = StreakProgressView()
        streakProgressView.translatesAutoresizingMaskIntoConstraints = false
        visualContainerView.addSubview(streakProgressView)

        NSLayoutConstraint.activate([
            streakProgressView.topAnchor.constraint(equalTo: visualContainerView.topAnchor),
            streakProgressView.leadingAnchor.constraint(equalTo: visualContainerView.leadingAnchor),
            streakProgressView.trailingAnchor.constraint(equalTo: visualContainerView.trailingAnchor),
            streakProgressView.bottomAnchor.constraint(equalTo: visualContainerView.bottomAnchor)
        ])
    }
}
