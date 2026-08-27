//
//  BorderView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 03/08/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

class BorderView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        backgroundColor = Colours.brandBlack.withAlphaComponent(0.2)
    }
}
