//
//  TableContentSheetViewController.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 08/08/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

final class TableContentSheetViewController: BottomSheetController {

    private let childTableViewController: UITableViewController
    init(childTableViewController: UITableViewController) {
        self.childTableViewController = childTableViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var thingsNavigationController: UINavigationController = {
        let navigationController = UINavigationController(rootViewController: childTableViewController)
        navigationController.view.translatesAutoresizingMaskIntoConstraints = false
        return navigationController
    }()

    override func loadView() {
        view = UIView()

        addChild(thingsNavigationController)

        view.addSubview(thingsNavigationController.view)

        NSLayoutConstraint.activate([
            thingsNavigationController.view.topAnchor.constraint(equalTo: view.topAnchor),
            thingsNavigationController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            thingsNavigationController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            thingsNavigationController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        thingsNavigationController.didMove(toParent: self)
    }
}
