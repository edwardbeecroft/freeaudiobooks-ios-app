//
//  BookPicksView.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 27/01/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import SwiftUI

// MARK: - SwiftUI Content View

struct BookPicksContent: View {

    let primaryGenre: BookInternalGenre?

    @State private var isAnimated = false

    private let containerBackgroundColor = Color(Colours.surfaceSecondary)
    private let accentColor = Color(Colours.orangePrimary)
    private let charcoalColor = Color(Colours.textPrimary)
    private let subtextColor = Color(Colours.textSecondary)

    // Book cover image names from BookCovers folder
    // Returns [front, middle, back] books based on genre
    private var bookImages: [String] {
        return imagesForGenre(primaryGenre)
    }

    /// Maps a genre to 3 ebook cover image names [front, middle, back]
    private func imagesForGenre(_ genre: BookInternalGenre?) -> [String] {
        guard let genre = genre else { return ["romance-9", "romance-10", "romance-11"] }

        switch genre {
        case .romance:
            return ["romance-14", "romance-6", "romance-7"]
        case .thriller:
            return ["thriller-11", "thriller-2", "thriller-3"]
        case .drama:
            return ["drama-13", "drama-2", "drama-3"]
        case .mystery:
            return ["mystery-13", "mystery-2", "mystery-3"]
        case .fantasy:
            return ["fantasy-11", "fantasy-2", "fantasy-3"]
        case .adventure:
            return ["adventure-12", "adventure-2", "adventure-3"]
        case .historical:
            return ["historical-13", "historical-2", "historical-3"]
        case .scienceFiction:
            return ["scifi-11", "scifi-3", "scifi-1"]
        case .horror:
            return ["horror-11", "horror-2", "horror-3"]
        case .comedy:
            return ["comedy-11", "comedy-2", "comedy-3"]
        case .kids:
            return ["kids-11", "kids-3", "kids-2"]
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Stacked book cards
            ZStack {
                ForEach(Array(bookImages.enumerated().reversed()), id: \.offset) { index, imageName in
                    bookCard(imageName: imageName, index: index)
                }
            }
            .frame(width: 220, height: 200)

            // Label
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(accentColor)

                Text("Today's picks for you")
                    .font(Font(Fonts.medium16))
                    .foregroundColor(charcoalColor)
            }
        }
        .padding(20)
        .background(containerBackgroundColor)
        .cornerRadius(16)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isAnimated = true
                }
            }
        }
    }

    private func bookCard(imageName: String, index: Int) -> some View {
        let offset = CGFloat(index) * 15
        let scale = 1.0 - (CGFloat(index) * 0.06)
        let rotation = Double(index - 1) * 5 // -5, 0, 5 degrees

        // Book covers are sourced from the asset catalog by name.
        let uiImage = UIImage(named: imageName) ?? UIImage()

        return Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(2.0 / 3.0, contentMode: .fill)
            .frame(width: 110, height: 165)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: Color(Colours.shadowBase).opacity(0.15), radius: 10, x: 0, y: 5)
            .rotationEffect(.degrees(isAnimated ? rotation : 0))
            .offset(x: isAnimated ? CGFloat(index - 1) * 38 : 0, y: offset)
            .scaleEffect(isAnimated ? scale : 0.8)
            .opacity(isAnimated ? 1 : 0)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.7)
                    .delay(Double(2 - index) * 0.1),
                value: isAnimated
            )
    }
}

// MARK: - UIKit Wrapper

final class BookPicksView: UIView {

    private var hostingController: UIHostingController<BookPicksContent>?
    private let primaryGenre: BookInternalGenre?

    init(primaryGenre: BookInternalGenre? = nil) {
        self.primaryGenre = primaryGenre
        super.init(frame: .zero)
        setupHostingController()
    }

    override init(frame: CGRect) {
        self.primaryGenre = nil
        super.init(frame: frame)
        setupHostingController()
    }

    required init?(coder: NSCoder) {
        self.primaryGenre = nil
        super.init(coder: coder)
        setupHostingController()
    }

    private func setupHostingController() {
        let hosting = UIHostingController(rootView: BookPicksContent(primaryGenre: primaryGenre))
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
