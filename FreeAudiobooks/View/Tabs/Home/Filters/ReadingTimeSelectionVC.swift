//
//  ReadingTimeSelectionVC.swift
//  FreeAudiobooks
//
//  Created by Claude Code on 21/03/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

protocol ReadingTimeSelectionDelegate: AnyObject {
    func didSelectReadingTime(_ bucket: CDBookInternalLengthBucket)
}

class ReadingTimeSelectionVC: BottomSheetController {

    // MARK: - Properties

    weak var delegate: ReadingTimeSelectionDelegate?

    private let buckets = CDBookInternalLengthBucket.allCases

    // MARK: - UI

    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let tableView = UITableView()

    // MARK: - Init

    init() {
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

        titleLabel.text = "Listening Time"
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
        tableView.register(SelectionTableViewCell.self, forCellReuseIdentifier: "ReadingTimeCell")
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
            tableView.heightAnchor.constraint(equalToConstant: CGFloat(buckets.count) * 50)
        ])
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension ReadingTimeSelectionVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return buckets.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReadingTimeCell", for: indexPath) as! SelectionTableViewCell
        let bucket = buckets[indexPath.row]
        let displayText: String
        switch bucket {
        case .short: displayText = "Short (under 30 min)"
        case .medium: displayText = "Medium (30–90 min)"
        case .long: displayText = "Long (90+ min)"
        }
        cell.configure(with: displayText, isSelected: false)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ReadingTimeSelectionVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let bucket = buckets[indexPath.row]
        delegate?.didSelectReadingTime(bucket)
        dismiss(animated: true)
    }
}
