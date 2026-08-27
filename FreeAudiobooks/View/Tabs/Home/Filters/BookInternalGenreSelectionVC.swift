//
//  BookInternalGenreSelectionVC.swift
//  FreeAudiobooks
//
//  Created by Claude on 09/09/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

protocol BookInternalGenreSelectionDelegate: AnyObject {
    func didSelectGenre(_ genre: BookInternalGenre)
    func didClearGenre()
}

class BookInternalGenreSelectionVC: BottomSheetController {

    // MARK: - Properties

    weak var delegate: BookInternalGenreSelectionDelegate?
    private var selectedGenre: BookInternalGenre?

    private let allGenres = BookInternalGenre.allCases

    // MARK: - UI

    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let clearButton = UIButton(type: .system)
    private let tableView = UITableView()

    // MARK: - Init

    init(selectedGenre: BookInternalGenre? = nil) {
        self.selectedGenre = selectedGenre
        super.init(nibName: nil, bundle: nil)
        preferredSheetSizing = .large
        preferredSheetCornerRadius = 24
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = Colours.surfaceCard
        view.layer.masksToBounds = true

        setupHeader()
        setupTableView()
        setupConstraints()
    }

    private func setupHeader() {
        headerView.backgroundColor = Colours.surfaceCard
        view.addSubviewForConstraints(headerView)

        titleLabel.text = "Genre"
        titleLabel.font = Fonts.bold19
        titleLabel.textColor = Colours.textPrimary

        let closeImage = UIImage(systemName: "xmark")
        closeButton.setImage(closeImage, for: .normal)
        closeButton.tintColor = Colours.textPrimary
        closeButton.backgroundColor = Colours.backgroundGrey
        closeButton.layer.cornerRadius = 16
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        headerView.addSubviewForConstraints(titleLabel)
        headerView.addSubviewForConstraints(closeButton)

        if selectedGenre != nil {
            clearButton.setTitle("Clear", for: .normal)
            clearButton.setTitleColor(Colours.lightUI, for: .normal)
            clearButton.titleLabel?.font = Fonts.medium15
            clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
            headerView.addSubviewForConstraints(clearButton)

            NSLayoutConstraint.activate([
                clearButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
                clearButton.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -12)
            ])
        }

        let divider = UIView()
        divider.backgroundColor = Colours.separator
        headerView.addSubviewForConstraints(divider)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),

            closeButton.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            divider.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = Colours.surfaceCard
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.register(SelectionTableViewCell.self, forCellReuseIdentifier: "GenreCell")
        view.addSubviewForConstraints(tableView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 52),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.heightAnchor.constraint(equalToConstant: CGFloat(allGenres.count) * 50)
        ])
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func clearTapped() {
        delegate?.didClearGenre()
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension BookInternalGenreSelectionVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allGenres.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GenreCell", for: indexPath) as! SelectionTableViewCell
        let genre = allGenres[indexPath.row]
        cell.configure(with: genre.displayString, isSelected: genre == selectedGenre)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension BookInternalGenreSelectionVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedGenre = allGenres[indexPath.row]
        delegate?.didSelectGenre(selectedGenre)
        dismiss(animated: true)
    }
}
