//
//  PersonalizedPicksAnimationView.swift
//  FreeAudiobooks
//
//  Sorting animation with hero stack, genre pill, and routine chips.
//
//  Created by Claude Code on 2026-01-28.
//

import SwiftUI
import Combine

// MARK: - Controller

final class PicksAnimationController: ObservableObject {
    @Published var isAnimating: Bool = true
}

// MARK: - SwiftUI View

struct PersonalizedPicksAnimationView: View {

    let selectedGenres: [BookInternalGenre]
    let dailyGoal: Int
    let reminderText: String
    let title: String

    let listeningReasons: [String]
    let showBadge: Bool
    let subtitle: String?

    @ObservedObject var controller: PicksAnimationController

    // MARK: Animation state

    enum Phase {
        case scattered
        case merging
        case final
    }

    @State private var phase: Phase = .scattered
    @State private var titleOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var animationTask: Task<Void, Never>?

    // Card deal animation states
    @State private var showHero: Bool = false
    @State private var heroScale: CGFloat = 0.5
    @State private var showPeeks: Bool = false
    @State private var showCard: Bool = false
    @State private var showMosaic: Bool = false
    @State private var displayedBookCount: Double = 0
    @State private var finishedNaturally: Bool = false

    // MARK: Styling

    private let accentColor = Color(Colours.orangePrimary)
    private let charcoalColor = Color(Colours.textPrimary)
    private let subtextColor = Color(Colours.textSecondary)

    // MARK: Scattered covers

    private let scatteredCovers = [
        "romance-1", "romance-4", "thriller-1", "thriller-3",
        "fantasy-1", "mystery-1", "horror-1", "adventure-1",
        "drama-1", "comedy-1", "scifi-1", "historical-1"
    ]

    private let scatteredPositions: [(x: CGFloat, y: CGFloat, rotation: Double)] = [
        (-110, -130, -15), (90, -150, 12), (140, -85, -8),
        (-140, -40, 20), (110, 15, -18), (-90, 70, 10),
        (70, 95, -12), (-125, 140, 8), (100, 160, -20),
        (-70, -175, 15), (50, -65, -10), (-50, 115, 5)
    ]

    // MARK: Final covers

    private func coversForGenre(_ genre: BookInternalGenre?) -> [String] {
        guard let genre = genre else { return ["romance-3", "romance-2", "romance-7"] }
        switch genre {
        case .romance:
            let firstRomanceCoverImage = RCValues.shared.string(forKey: .onbPersonalizedPicksRomanceImagev2)
            return ["romance-\(firstRomanceCoverImage)", "romance-17", "romance-13"]
        case .thriller: return ["thriller-11", "thriller-16", "thriller-2"]
        case .drama: return ["drama-17", "drama-12", "drama-3"]
        case .mystery: return ["mystery-12", "mystery-14", "mystery-11"]
        case .fantasy: return ["fantasy-14", "fantasy-16", "fantasy-3"]
        case .adventure: return ["adventure-15", "adventure-11", "adventure-13"]
        case .historical: return ["historical-11", "historical-12", "historical-14"]
        case .scienceFiction: return ["scifi-1", "scifi-2", "scifi-3"]
        case .horror: return ["horror-1", "horror-2", "horror-4"]
        case .comedy: return ["comedy-1", "comedy-2", "comedy-3"]
        case .kids: return ["kids-12", "kids-13", "kids-3"]
        }
    }

    private var finalHero: String {
        coversForGenre(selectedGenres.first).first ?? "romance-3"
    }

    private var finalLeftPeek: String {
        let primary = coversForGenre(selectedGenres.first)
        let secondary = selectedGenres.count > 1 ? coversForGenre(selectedGenres[1]) : primary
        return (secondary.count > 1 ? secondary[1] : primary.dropFirst().first) ?? finalHero
    }

    private var finalRightPeek: String {
        let primary = coversForGenre(selectedGenres.first)
        let secondary = selectedGenres.count > 1 ? coversForGenre(selectedGenres[1]) : primary
        return (secondary.count > 2 ? secondary[2] : (primary.count > 2 ? primary[2] : finalHero))
    }

    private let displayBookCount: Int = 350

    /// Genre summary text (e.g., "Mystery + 3 more")
    private var genreSummaryText: String {
        guard !selectedGenres.isEmpty else { return "your favorites" }

        if selectedGenres.count == 1 {
            return selectedGenres[0].displayString
        } else {
            let extra = selectedGenres.count - 1
            return "\(selectedGenres[0].displayString) + \(extra) more"
        }
    }

    /// Listening reason summary text (e.g., "Curiosity + 2 more")
    private var reasonSummaryText: String? {
        guard !listeningReasons.isEmpty else { return nil }

        let first = formatReason(listeningReasons[0])

        if listeningReasons.count == 1 {
            return first
        } else {
            let extra = listeningReasons.count - 1
            return "\(first) + \(extra) more"
        }
    }

    private func formatReason(_ reason: String) -> String {
        switch reason {
        case "entertainment": return "Entertainment"
        case "escapism": return "Escapism"
        case "relaxation": return "Relaxation"
        case "inspiration": return "Inspiration"
        case "curiosity": return "Curiosity"
        default: return reason.capitalized
        }
    }

    /// Mosaic covers - curated mix for contained card (16 covers)
    private let mosaicCovers = [
        "romance-1", "thriller-1", "fantasy-1", "mystery-1",
        "drama-1", "adventure-1", "historical-1", "scifi-1",
        "romance-2", "thriller-2", "fantasy-2", "mystery-2",
        "horror-1", "comedy-1", "romance-3", "thriller-3"
    ]

    // MARK: Reference dimensions (iPhone 14 Pro)

    private let referenceWidth: CGFloat = 393
    private let referenceHeight: CGFloat = 852

    // MARK: Body

    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let centerY = geo.size.height * 0.35

            // Scale based on width only (height varies too much due to safe areas, buttons, etc.)
            let scale = geo.size.width / referenceWidth

            ZStack {
                // Clean white background
                Color(Colours.surfacePrimary)

                // Scattered covers (initial animation)
                ForEach(0..<scatteredCovers.count, id: \.self) { idx in
                    scatteredCover(index: idx, centerX: centerX, centerY: centerY, scale: scale, screenWidth: geo.size.width)
                }

                // Main content
                VStack(spacing: 0) {
                    // Title - left-aligned like other screens
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(charcoalColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .opacity(titleOpacity)
                        .animation(.easeIn(duration: 0.35), value: titleOpacity)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color(Colours.textSecondary))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .opacity(titleOpacity)
                            .animation(.easeIn(duration: 0.35), value: titleOpacity)
                    }

                    Spacer()

                    // Contained library card with mosaic + hero stack
                    libraryCard(geo: geo)
                        .padding(.horizontal, 24)
                        .opacity(showCard ? 1 : 0)
                        .animation(.easeOut(duration: 0.4), value: showCard)

                    Spacer()

                    // Your routine section
                    VStack(spacing: 8) {
                        Text("Your routine")
                            .font(Font(Fonts.semiBold14))
                            .foregroundColor(charcoalColor)

                        HStack(spacing: 8) {
                            // Goal pill
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.trianglehead.2.clockwise")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(accentColor)
                                Text("\(dailyGoal) min/day")
                                    .font(Font(Fonts.medium13))
                                    .foregroundColor(charcoalColor)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(accentColor.opacity(0.1))
                            .cornerRadius(16)

                            // Reminder pill
                            HStack(spacing: 5) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(accentColor)
                                Text(reminderText)
                                    .font(Font(Fonts.medium13))
                                    .foregroundColor(charcoalColor)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(accentColor.opacity(0.1))
                            .cornerRadius(16)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .opacity(contentOpacity)
                    .animation(.easeIn(duration: 0.35).delay(0.1), value: contentOpacity)
                }
            }
            .onAppear { startAnimationIfNeeded() }
            .onChange(of: controller.isAnimating) { isAnimating in
                guard !isAnimating, !finishedNaturally else { return }
                skipToFinalState()
            }
        }
    }

    // MARK: - Library Card (Contained Mosaic)

    @ViewBuilder
    private func libraryCard(geo: GeometryProxy) -> some View {
        let cardWidth = geo.size.width - 48  // 24pt padding on each side
        let cardHeight: CGFloat = 320

        VStack(spacing: 0) {
            ZStack {
                // Card background with subtle mosaic
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(Colours.surfaceSecondary))
                    .overlay {
                        // Only build mosaic when needed (performance optimization)
                        if showMosaic {
                            mosaicGrid(cardWidth: cardWidth, cardHeight: cardHeight)
                                .opacity(0.45)
                                .blur(radius: 4)
                                .transition(.opacity.animation(.easeOut(duration: 0.6)))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                // Hero stack in center
                finalBooksStack()

                // "N+ more" badge in top-right corner (soft outline style)
                VStack {
                    HStack {
                        Spacer()
                        Text("\(Int(displayedBookCount.rounded()))+ more")
                            .font(Font(Fonts.medium13))
                            .foregroundColor(accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .stroke(accentColor.opacity(0.5), lineWidth: 1.5)
                                    .background(Capsule().fill(Color(Colours.surfacePrimary).opacity(0.9)))
                            )
                            .opacity(showMosaic && showBadge ? 1 : 0)
                            .animation(.easeIn(duration: 0.3).delay(0.2), value: showMosaic)
                    }
                    .padding(12)
                    Spacer()
                }
            }
            .frame(height: cardHeight)

            // Genre + Goals chips below the card
            HStack(spacing: 8) {
                // Genre chip
                HStack(spacing: 5) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(accentColor)
                    Text(genreSummaryText)
                        .font(Font(Fonts.medium13))
                        .foregroundColor(charcoalColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(accentColor.opacity(0.1))
                .cornerRadius(16)

                // Goals chip (only if reasons exist)
                if let reasonText = reasonSummaryText {
                    HStack(spacing: 5) {
                        Image(systemName: "target")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(accentColor)
                        Text(reasonText)
                            .font(Font(Fonts.medium13))
                            .foregroundColor(charcoalColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(accentColor.opacity(0.1))
                    .cornerRadius(16)
                }
            }
            .padding(.top, 12)
            .opacity(contentOpacity)
            .animation(.easeIn(duration: 0.35), value: contentOpacity)
        }
    }

    /// 4x4 grid of covers for the contained mosaic (16 covers total)
    @ViewBuilder
    private func mosaicGrid(cardWidth: CGFloat, cardHeight: CGFloat) -> some View {
        let columns = 4
        let rows = 4
        let spacing: CGFloat = 4
        let coverWidth = (cardWidth - CGFloat(columns + 1) * spacing) / CGFloat(columns)
        let coverHeight = coverWidth * 1.5

        VStack(spacing: spacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<columns, id: \.self) { col in
                        let index = (row * columns + col) % mosaicCovers.count
                        localCoverImage(named: mosaicCovers[index])
                            .frame(width: coverWidth, height: coverHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
        .padding(spacing)
    }

    // MARK: - Scattered Cover

    @ViewBuilder
    private func scatteredCover(index: Int, centerX: CGFloat, centerY: CGFloat, scale: CGFloat, screenWidth: CGFloat) -> some View {
        let pos = scatteredPositions[index % scatteredPositions.count]
        let name = scatteredCovers[index]

        // Scale positions based on screen size
        let scaledX = pos.x * scale
        let scaledY = pos.y * scale

        // Clamp x position to keep books visible (with 35pt margin for half book width)
        let margin: CGFloat = 35
        let maxOffsetX = (screenWidth / 2) - margin
        let clampedX = max(-maxOffsetX, min(maxOffsetX, scaledX))

        let mergeFactor: CGFloat = (phase == .scattered) ? 1.0 : 0.22
        let x = centerX + (clampedX * mergeFactor)
        let y = centerY + (scaledY * mergeFactor)

        // Scattered covers fade out as they merge, gone before final
        let opacity: Double = (phase == .scattered) ? 0.55 : 0.0

        let blur: CGFloat = (phase == .scattered) ? 1 : 3

        // Scale book size slightly on smaller screens
        let bookWidth: CGFloat = 70 * min(scale, 1.0)
        let bookHeight: CGFloat = 105 * min(scale, 1.0)

        // Stagger delay: outer books start first, inner books follow
        let staggerDelay = Double(index) * 0.04

        localCoverImage(named: name)
            .frame(width: bookWidth, height: bookHeight)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(color: .black.opacity(0.10), radius: 4, x: 0, y: 2)
            .rotationEffect(.degrees(phase == .scattered ? pos.rotation : pos.rotation * 0.2))
            .position(x: x, y: y)
            .opacity(opacity)
            .blur(radius: blur)
            .animation(
                .timingCurve(0.7, 0, 0.9, 0.4, duration: 0.9).delay(staggerDelay),
                value: phase
            )
    }

    // MARK: - Hero Stack

    @ViewBuilder
    private func finalBooksStack() -> some View {
        // Peek books: start behind hero (no offset/rotation), then fan out
        let peekOffset: CGFloat = showPeeks ? 68 : 0
        let peekRotation: Double = showPeeks ? 16 : 0
        let peekYOffset: CGFloat = showPeeks ? 15 : 0
        let peekScale: CGFloat = showPeeks ? 0.85 : 0.7

        ZStack {
            // Left peek - starts behind hero, fans out to the left
            localCoverImage(named: finalLeftPeek)
                .frame(width: 110, height: 165)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                .rotationEffect(.degrees(-peekRotation))
                .offset(x: -peekOffset, y: peekYOffset)
                .scaleEffect(peekScale)
                .opacity(showHero ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05), value: showPeeks)

            // Right peek - starts behind hero, fans out to the right
            localCoverImage(named: finalRightPeek)
                .frame(width: 110, height: 165)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                .rotationEffect(.degrees(peekRotation))
                .offset(x: peekOffset, y: peekYOffset)
                .scaleEffect(peekScale)
                .opacity(showHero ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: showPeeks)

            // Hero - appears first with scale overshoot
            localCoverImage(named: finalHero)
                .frame(width: 150, height: 225)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)
                .scaleEffect(heroScale)
                .opacity(showHero ? 1.0 : 0.0)
                .animation(.spring(response: 0.45, dampingFraction: 0.6), value: heroScale)
                .animation(.easeOut(duration: 0.2), value: showHero)
        }
    }

    // MARK: - Cover Image

    @ViewBuilder
    private func localCoverImage(named name: String) -> some View {
        Image(name)
            .resizable()
            .aspectRatio(contentMode: .fill)
    }

    // MARK: - Animation

    private func startAnimationIfNeeded() {
        guard controller.isAnimating else {
            skipToFinalState()
            return
        }

        animationTask?.cancel()
        phase = .scattered
        titleOpacity = 0
        contentOpacity = 0
        showHero = false
        heroScale = 0.5
        showPeeks = false
        showCard = false
        showMosaic = false
        displayedBookCount = 0
        finishedNaturally = false

        animationTask = Task { @MainActor in
            // Brief pause before animation starts
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard controller.isAnimating, !Task.isCancelled else { return }

            // Scattered books merge and fade (slow start, speeds up)
            phase = .merging

            // Wait for books to converge (longer duration for the gravitational pull)
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard controller.isAnimating, !Task.isCancelled else { return }

            // Card fades in as scattered books fade out
            showCard = true

            // Brief moment for card to appear
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard controller.isAnimating, !Task.isCancelled else { return }

            // Hero lands with overshoot + haptic
            showHero = true
            heroScale = 1.08  // Overshoot
            HapticFeedbackHelper.shared.triggerLightImpactFeedback()

            // Hero settles to final scale
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard controller.isAnimating, !Task.isCancelled else { return }
            heroScale = 1.0

            // Peek books fan out from behind hero
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard controller.isAnimating, !Task.isCancelled else { return }
            showPeeks = true

            // Wait for fan animation to complete
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard controller.isAnimating, !Task.isCancelled else { return }

            phase = .final

            // Reveal mosaic wall behind hero
            showMosaic = true

            // Count-up animation for badge (0 → 350 over ~500ms)
            animateCountUp()

            // Fade in title
            titleOpacity = 1

            try? await Task.sleep(nanoseconds: 150_000_000)
            guard controller.isAnimating, !Task.isCancelled else { return }

            // Fade in content
            contentOpacity = 1

            try? await Task.sleep(nanoseconds: 400_000_000)
            finishedNaturally = true
            controller.isAnimating = false
        }
    }

    private func skipToFinalState() {
        animationTask?.cancel()
        animationTask = nil
        phase = .final
        showCard = true
        showHero = true
        heroScale = 1.0
        showPeeks = true
        showMosaic = true
        displayedBookCount = Double(displayBookCount)
        titleOpacity = 1
        contentOpacity = 1
    }

    /// Animates the book count from 0 to displayBookCount using SwiftUI animation
    private func animateCountUp() {
        displayedBookCount = 0
        withAnimation(.easeOut(duration: 0.6)) {
            displayedBookCount = Double(displayBookCount)
        }
    }
}

// MARK: - UIKit Wrapper

final class PersonalizedPicksAnimationWrapper: UIView {

    private let controller = PicksAnimationController()
    private var hostingController: UIHostingController<PersonalizedPicksAnimationView>?
    private var cancellables: Set<AnyCancellable> = []

    var onAnimationComplete: (() -> Void)?

    init(selectedGenres: [BookInternalGenre], dailyGoal: Int, reminderText: String, title: String, listeningReasons: [String] = [], showBadge: Bool = true, subtitle: String? = nil) {
        super.init(frame: .zero)

        let root = PersonalizedPicksAnimationView(
            selectedGenres: selectedGenres,
            dailyGoal: dailyGoal,
            reminderText: reminderText,
            title: title,
            listeningReasons: listeningReasons,
            showBadge: showBadge,
            subtitle: subtitle,
            controller: controller
        )

        let hosting = UIHostingController(rootView: root)
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

        controller.$isAnimating
            .removeDuplicates()
            .sink { [weak self] isAnimating in
                guard let self else { return }
                if !isAnimating {
                    self.onAnimationComplete?()
                }
            }
            .store(in: &cancellables)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func skipAnimation() {
        controller.isAnimating = false
    }

    func restartAnimation() {
        controller.isAnimating = true
    }
}
