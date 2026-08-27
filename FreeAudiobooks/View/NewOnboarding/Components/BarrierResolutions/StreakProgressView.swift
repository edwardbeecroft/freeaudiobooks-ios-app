//
//  StreakProgressView.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 27/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import SwiftUI

// MARK: - SwiftUI Content View

struct StreakProgressContent: View {

    @State private var animatedDays: Int = 0

    private let containerBackgroundColor = Color(Colours.surfaceSecondary)
    private let accentColor = Color(Colours.orangePrimary)
    private let charcoalColor = Color(Colours.textPrimary)
    private let subtextColor = Color(Colours.textSecondary)
    private let emptyDotColor = Color(Colours.inputBorder)

    // Number of days to fill in each week (upward trend showing habit building)
    private let weekProgress: [Int] = [3, 4, 5, 6] // Realistic growth, Week 4 strong but not perfect
    private let totalDays = 7

    var body: some View {
        VStack(spacing: 20) {
            // Week rows
            ForEach(Array(weekProgress.enumerated()), id: \.offset) { weekIndex, filledDays in
                weekRow(weekNumber: weekIndex + 1, filledDays: filledDays, weekIndex: weekIndex)
            }
        }
        .padding(20)
        .background(containerBackgroundColor)
        .cornerRadius(16)
        .onAppear {
            animateProgress()
        }
    }

    private func weekRow(weekNumber: Int, filledDays: Int, weekIndex: Int) -> some View {
        HStack(spacing: 8) {
            // Week label
            Text("Week \(weekNumber)")
                .font(Font(Fonts.medium14))
                .foregroundColor(subtextColor)
                .frame(width: 60, alignment: .leading)

            // Progress dots
            HStack(spacing: 6) {
                ForEach(0..<totalDays, id: \.self) { dayIndex in
                    // Calculate animation order: sum of all previous weeks' filled days + current day
                    let previousWeeksDays = weekProgress.prefix(weekIndex).reduce(0, +)
                    let animationOrder = previousWeeksDays + dayIndex
                    let shouldFill = dayIndex < filledDays && animationOrder < animatedDays

                    Circle()
                        .fill(shouldFill ? accentColor : emptyDotColor)
                        .frame(width: 24, height: 24)
                        .scaleEffect(shouldFill ? 1.0 : 0.85)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.6)
                                .delay(Double(animationOrder) * 0.05),
                            value: animatedDays
                        )
                }
            }
        }
    }

    private func animateProgress() {
        // Total filled days across all weeks
        let totalDaysToAnimate = weekProgress.reduce(0, +)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                animatedDays = totalDaysToAnimate
            }
        }
    }
}

// MARK: - UIKit Wrapper

final class StreakProgressView: UIView {

    private var hostingController: UIHostingController<StreakProgressContent>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHostingController()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHostingController()
    }

    private func setupHostingController() {
        let hosting = UIHostingController(rootView: StreakProgressContent())
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false

        addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        hostingController = hosting
    }
}
