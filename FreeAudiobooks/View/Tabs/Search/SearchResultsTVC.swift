//
//  SearchResultsTVC.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 05/08/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import Kingfisher

class SearchResultsTVC: UITableViewCell {
    
    var tappedSaveHandler: ((SaveableMetadataView) -> Void)?
    var tappedDownloadHandler: ((DownloadableMetadataView) -> Void)?
    var tappedHandler: (() -> Void)?

    private var bookMetadata: ReadableContentMetadata?
    func set(contentMetadata: ReadableContentMetadata, displayContext: SmallMetadataDisplayContext) {
        self.bookMetadata = contentMetadata
        bookMetadataView.set(contentMetadata: contentMetadata, displayContext: displayContext)
        bookMetadataView.updateSaveElements()
    }
    
    private let bookMetadataView = SmallMetadataView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupMetadataView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
}

extension SearchResultsTVC {
    func setupMetadataView() {
        contentView.addSubviewForConstraints(bookMetadataView)
        NSLayoutConstraint.activate([
            bookMetadataView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bookMetadataView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bookMetadataView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bookMetadataView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        bookMetadataView.tappedSaveHandler = { [weak self] view in
            guard let self else { return }
            DispatchQueue.main.async {
                self.tappedSaveHandler?(view)
            }
        }
        bookMetadataView.tappedDownloadHandler = { [weak self] view in
            guard let self else { return }
            DispatchQueue.main.async {
                self.tappedDownloadHandler?(view)
            }
        }
        bookMetadataView.tappedHandler = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.tappedHandler?()
            }
        }
    }
}
