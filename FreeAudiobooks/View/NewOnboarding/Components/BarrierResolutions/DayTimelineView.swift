//
//  DayTimelineView.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 27/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import SwiftUI

// MARK: - Trail Stop Model

struct TrailStop {
    let icon: String
    let title: String
    let subtitle: String
}

// MARK: - Anchor Preference (Long-term robust layout)

private struct StopAnchorKey: PreferenceKey {
    static var defaultValue: [Int: Anchor<CGPoint>] = [:]

    static func reduce(value: inout [Int : Anchor<CGPoint>], nextValue: () -> [Int : Anchor<CGPoint>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - SwiftUI Content View

struct DayTimelineContent: View {

    private let stops: [TrailStop] = [
        TrailStop(icon: "hand.tap", title: "Open", subtitle: "Tap to jump in"),
        TrailStop(icon: "sparkles", title: "Discover", subtitle: "Picks ready for you"),
        TrailStop(icon: "headphones", title: "Listen", subtitle: "Start in seconds")
    ]

    private let containerBackgroundColor = Color(Colours.surfaceSecondary)
    private let accentColor = Color(Colours.orangePrimary)
    private let charcoalColor = Color(Colours.textPrimary)
    private let subtextColor = Color(Colours.textSecondary)
    private let trailColor = Color(Colours.inputBorder)

    @State private var pathProgress: CGFloat = 0
    @State private var visibleStops: Set<Int> = []
    @State private var showBadge = false

    private let markerSize: CGFloat = 40
    private let stopHeight: CGFloat = 60
    private let rowSpacing: CGFloat = 26
    private let cardCornerRadius: CGFloat = 16

    var body: some View {
        ZStack(alignment: .topTrailing) {
            card
            badge
        }
        .onAppear { animateJourney() }
    }

    // MARK: - Card

    private var card: some View {
        // The rows that define marker anchors
        let rows = VStack(spacing: rowSpacing) {
            ForEach(Array(stops.enumerated()), id: \.offset) { index, stop in
                stopRow(stop: stop, index: index, isLeft: index % 2 == 0)
            }
        }
        .padding(.vertical, 8)
        // Draw the path BEHIND the rows using the resolved anchors
        .backgroundPreferenceValue(StopAnchorKey.self) { anchors in
            GeometryReader { proxy in
                let points: [CGPoint] = (0..<stops.count).compactMap { idx in
                    guard let anchor = anchors[idx] else { return nil }
                    return proxy[anchor]
                }

                ZStack {
                    timelinePath(points: points)
                        .stroke(trailColor, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [8, 6]))

                    timelinePath(points: points)
                        .trim(from: 0, to: pathProgress)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                }
                .allowsHitTesting(false)
            }
        }

        return rows
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(containerBackgroundColor)
            .cornerRadius(cardCornerRadius)
    }

    // MARK: - Badge

    private var badge: some View {
        Text("3 taps")
            .font(Font(Fonts.semiBold16))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(accentColor)
            .cornerRadius(14)
            .shadow(color: accentColor.opacity(0.25), radius: 8, x: 0, y: 4)
            .rotationEffect(.degrees(12))
            .offset(x: 8, y: -12)
            .scaleEffect(showBadge ? 1 : 0.3)
            .opacity(showBadge ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.65), value: showBadge)
    }

    // MARK: - Rows

    private func stopRow(stop: TrailStop, index: Int, isLeft: Bool) -> some View {
        let isVisible = visibleStops.contains(index)

        return HStack(spacing: 12) {
            if !isLeft {
                Spacer().frame(width: 60)
            }

            // Marker circle (anchor on center)
            ZStack {
                Circle()
                    .fill(isVisible ? accentColor : trailColor)
                    .frame(width: markerSize, height: markerSize)

                Image(systemName: stop.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .anchorPreference(key: StopAnchorKey.self, value: .center) { anchor in
                [index: anchor]
            }
            .scaleEffect(isVisible ? 1 : 0.7)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isVisible)

            // Content bubble
            VStack(alignment: .leading, spacing: 2) {
                Text(stop.title)
                    .font(Font(Fonts.semiBold16))
                    .foregroundColor(charcoalColor)

                Text(stop.subtitle)
                    .font(Font(Fonts.regular14))
                    .foregroundColor(subtextColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(Colours.surfacePrimary))
            .cornerRadius(12)
            .shadow(color: Color(Colours.shadowBase).opacity(0.06), radius: 8, x: 0, y: 2)
            .opacity(isVisible ? 1 : 0)
            .offset(x: isVisible ? 0 : -10)
            .animation(.easeOut(duration: 0.3).delay(0.1), value: isVisible)

            if isLeft {
                Spacer()
            }
        }
        .frame(height: stopHeight)
    }

    // MARK: - Path

    /// Smooth contained curve through all marker centers.
    /// Uses "midY" control points to keep the curve stable and within bounds.
    private func timelinePath(points: [CGPoint]) -> Path {
        Path { path in
            guard points.count >= 2 else { return }

            path.move(to: points[0])

            for i in 1..<points.count {
                let prev = points[i - 1]
                let curr = points[i]
                let midY = (prev.y + curr.y) / 2

                let c1 = CGPoint(x: prev.x, y: midY)
                let c2 = CGPoint(x: curr.x, y: midY)

                path.addCurve(to: curr, control1: c1, control2: c2)
            }
        }
    }

    // MARK: - Animation

    private func animateJourney() {
        pathProgress = 0
        visibleStops.removeAll()
        showBadge = false

        // Show first stop
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            visibleStops.insert(0)
        }

        // Draw path
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 1.1)) {
                pathProgress = 1.0
            }
        }

        // Show remaining stops
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            visibleStops.insert(1)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            visibleStops.insert(2)
        }

        // Show badge
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            showBadge = true
        }
    }
}

// MARK: - UIKit Wrapper

final class DayTimelineView: UIView {

    private var hostingController: UIHostingController<DayTimelineContent>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHostingController()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHostingController()
    }

    private func setupHostingController() {
        let hosting = UIHostingController(rootView: DayTimelineContent())
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
