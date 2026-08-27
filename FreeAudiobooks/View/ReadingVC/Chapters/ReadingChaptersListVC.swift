//
//  ReadingChaptersListVC.swift
//  FreeAudiobooks
//
//  Copyright © 2024 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

final class ReadingChaptersListVC: BottomSheetController {

    // MARK: - Properties

    var selectChapterHandler: ((_ chapterIndex: Int) -> Void)?
    var dismissHandler: (() -> Void)?

    private let totalSections: Int
    private let currentSection: Int
    private let contentType: ContentType

    // MARK: - UI Elements

    private let titleLabel = UILabel()
    private let dismissButton = UIButton(type: .system)
    private let borderView = SplitterView()
    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: - Init

    init(totalSections: Int, currentSection: Int, contentType: ContentType) {
        self.totalSections = totalSections
        self.currentSection = currentSection
        self.contentType = contentType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = UIView()
        view.backgroundColor = Colours.surfacePrimary

        setupHeader()
        setupTableView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Scroll to current chapter after layout
        DispatchQueue.main.async { [weak self] in
            guard let self, self.currentSection < self.totalSections else { return }
            let indexPath = IndexPath(row: self.currentSection, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
        }
    }

    // MARK: - Setup

    private func setupHeader() {
        titleLabel.text = contentType == .bookInternal ? "Chapters" : "Sections"
        titleLabel.font = Fonts.semiBold16
        titleLabel.textColor = Colours.textPrimary
        titleLabel.textAlignment = .center

        dismissButton.setImage(UIImage(named: "dismissIcon")?.withRenderingMode(.alwaysTemplate), for: [])
        dismissButton.tintColor = Colours.textSecondary
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)

        view.addSubviewForConstraints(titleLabel)
        view.addSubviewForConstraints(dismissButton)
        view.addSubviewForConstraints(borderView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            dismissButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            dismissButton.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -UIConstants.shared.standardMargin),
            dismissButton.heightAnchor.constraint(equalToConstant: 32),
            dismissButton.widthAnchor.constraint(equalToConstant: 32),

            borderView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            borderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            borderView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ReadingChaptersListTVC.self, forCellReuseIdentifier: ReadingChaptersListTVC.reuseIdentifier)
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = Colours.surfacePrimary
        tableView.separatorInset = UIEdgeInsets(top: 0, left: UIConstants.shared.standardMargin, bottom: 0, right: UIConstants.shared.standardMargin)

        view.addSubviewForConstraints(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: borderView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func dismissTapped() {
        dismissHandler?()
    }
}

// MARK: - UITableViewDataSource

extension ReadingChaptersListVC: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return totalSections
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReadingChaptersListTVC.reuseIdentifier, for: indexPath) as! ReadingChaptersListTVC

        let isCurrentChapter = indexPath.row == currentSection
        cell.configure(chapterIndex: indexPath.row, isCurrentChapter: isCurrentChapter, contentType: contentType)

        return cell
    }
}

// MARK: - UITableViewDelegate

extension ReadingChaptersListVC: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectChapterHandler?(indexPath.row)
    }
}
