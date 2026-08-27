//
//  FavoriteGenreSelectionVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 04/11/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

protocol FavoriteGenreSelectionDelegate: AnyObject {
    func didUpdateFavoriteGenres(_ genres: [BookInternalGenre])
}

final class FavoriteGenreSelectionVC: BottomSheetController {

    // MARK: - Properties

    weak var delegate: FavoriteGenreSelectionDelegate?
    private var selectedGenres: [BookInternalGenre]
    private let minimumGenresRequired = 1
    private var loadingIndicatorView: NVActivityIndicatorView?
    private var optionViews: [OnboardingOptionView] = []
    private var hasAnimatedEntrance = false

    // MARK: - UI Elements

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = Colours.textPrimary
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = Colours.subtext
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        sv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        return sv
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()

    private let continueButton = Buttons.primaryCTA(buttonTitle: "Select Genres")

    // MARK: - Initialization

    init(currentGenres: [BookInternalGenre] = []) {
        self.selectedGenres = currentGenres
        super.init(nibName: nil, bundle: nil)

        self.preferredSheetSizing = .large
        self.preferredSheetCornerRadius = UIConstants.shared.cornerRadius
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        createOptionViews()
        updateContinueButton()
        AnalyticsManager.shared.trackSelectFavoriteGenresViewed()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !hasAnimatedEntrance {
            hasAnimatedEntrance = true
            animateCellsEntrance()
        }
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        setupTitleLabel()
        setupSubtitleLabel()
        setupScrollView()
        setupContinueButton()
        setupConstraints()
    }

    private func setupTitleLabel() {
        let favoriteText = Locale.isUK ? "Favourite" : "Favorite"
        titleLabel.text = "Select Your \(favoriteText) Genres"
        view.addSubviewForConstraints(titleLabel)
    }

    private func setupSubtitleLabel() {
        let personalizeText = Locale.isUK ? "personalise" : "personalize"
        subtitleLabel.text = "Choose one or more genres to \(personalizeText) your listening experience"
        view.addSubviewForConstraints(subtitleLabel)
    }

    private func setupScrollView() {
        view.addSubviewForConstraints(scrollView)
        scrollView.addSubviewForConstraints(stackView)
    }

    private func setupContinueButton() {
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.heightAnchor.constraint(equalToConstant: UIConstants.shared.fullButtonHeight).isActive = true
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        continueButton.alpha = selectedGenres.count >= minimumGenresRequired ? 1.0 : 0.5

        view.addSubviewForConstraints(continueButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title - left aligned
            titleLabel.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -20),

            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -20),

            // Scroll view
            scrollView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            scrollView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -20),

            // Stack view inside scroll view
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Continue button
            continueButton.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -20),
            continueButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -20)
        ])
    }

    // MARK: - Option Views

    private func createOptionViews() {
        for genre in BookInternalGenre.allCases {
            let option = OnboardingOption(
                id: genre.rawValue,
                title: genre.displayString,
                icon: genreIcon(for: genre)
            )

            let optionView = OnboardingOptionView()
            let isSelected = selectedGenres.contains(genre)
            optionView.configure(with: option, isSelected: isSelected)

            optionView.translatesAutoresizingMaskIntoConstraints = false
            optionView.heightAnchor.constraint(equalToConstant: 72).isActive = true

            // Start hidden for entrance animation
            optionView.alpha = 0
            optionView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)

            optionView.onTap = { [weak self] optionId in
                self?.handleOptionTap(optionId)
            }

            stackView.addArrangedSubview(optionView)
            optionViews.append(optionView)
        }
    }

    private func genreIcon(for genre: BookInternalGenre) -> String {
        switch genre {
        case .thriller: return "bolt.fill"
        case .mystery: return "magnifyingglass"
        case .romance: return "heart.fill"
        case .fantasy: return "wand.and.stars"
        case .adventure: return "map.fill"
        case .scienceFiction: return "sparkles"
        case .comedy: return "face.smiling.fill"
        case .historical: return "clock.fill"
        case .drama: return "theatermasks.fill"
        case .horror: return "moon.stars.fill"
        case .kids: return "figure.and.child.holdinghands"
        }
    }

    // MARK: - Entrance Animation

    private func animateCellsEntrance() {
        for (index, optionView) in optionViews.enumerated() {
            let delay = Double(index) * 0.08
            UIView.animate(
                withDuration: 0.4,
                delay: delay,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.3,
                options: [.curveEaseOut]
            ) {
                optionView.alpha = 1
                optionView.transform = .identity
            }
        }
    }

    // MARK: - Selection Handling

    private func handleOptionTap(_ optionId: String) {
        guard let genre = BookInternalGenre(rawValue: optionId) else { return }

        if selectedGenres.contains(genre) {
            selectedGenres.removeAll { $0 == genre }
        } else {
            selectedGenres.append(genre)
        }

        // Update all option views
        for optionView in optionViews {
            if let genreForView = BookInternalGenre(rawValue: optionView.optionId) {
                let isSelected = selectedGenres.contains(genreForView)
                optionView.setSelected(isSelected, animated: true)
            }
        }

        updateContinueButton()
    }

    // MARK: - Actions

    @objc private func continueTapped() {
        guard selectedGenres.count >= minimumGenresRequired else { return }

        let genresArray = selectedGenres
        showLoadingIndicator(show: true)

        let genreStrings = genresArray.compactMap({ $0.rawValue })

        // Update local user object optimistically
        AccountManager.shared.user?.favoriteGenres = genresArray

        let data: [String: Any] = [
            FirebaseUserVariables.favoriteGenres.rawValue: genreStrings
        ]

        AccountManager.shared.updateUserWithData(data) { [weak self] success in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.showLoadingIndicator(show: false)

                if success {
                    AnalyticsManager.shared.trackSelectFavoriteGenresCompleted()
                    self.delegate?.didUpdateFavoriteGenres(genresArray)
                    self.dismiss(animated: true)
                } else {
                    self.showErrorAlert()
                }
            }
        }
    }

    private func showErrorAlert() {
        let alert = UIAlertController(
            title: "Error",
            message: "Failed to save your genre preferences. Please try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func updateContinueButton() {
        let count = selectedGenres.count

        if count == 0 {
            continueButton.setTitle("Select Genres", for: .normal)
            continueButton.alpha = 0.5
        } else if count < minimumGenresRequired {
            let remaining = minimumGenresRequired - count
            continueButton.setTitle("Select \(remaining) More", for: .normal)
            continueButton.alpha = 0.5
        } else {
            continueButton.setTitle("Continue", for: .normal)
            continueButton.alpha = 1.0
        }
    }

    private func showLoadingIndicator(show: Bool) {
        if show {
            guard loadingIndicatorView == nil else { return }

            continueButton.alpha = 0

            loadingIndicatorView = NVActivityIndicatorView(
                frame: .zero,
                type: .circleStrokeSpin,
                color: Colours.textPrimary,
                padding: 0
            )

            guard let indicatorView = loadingIndicatorView else { return }

            view.addSubviewForConstraints(indicatorView)
            NSLayoutConstraint.activate([
                indicatorView.centerYAnchor.constraint(equalTo: continueButton.centerYAnchor),
                indicatorView.centerXAnchor.constraint(equalTo: continueButton.centerXAnchor),
                indicatorView.widthAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight),
                indicatorView.heightAnchor.constraint(equalToConstant: UIConstants.shared.fetchingIndicatorWidthHeight)
            ])
            indicatorView.startAnimating()
        } else {
            loadingIndicatorView?.stopAnimating()
            loadingIndicatorView?.removeFromSuperview()
            loadingIndicatorView = nil

            updateContinueButton()
        }
    }
}
