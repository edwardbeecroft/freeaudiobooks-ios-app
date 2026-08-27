//
//  UIShortTapGestureRecognizer.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 06/09/2020.
//  Copyright © 2020 Radically Better Ltd. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class UIShortTapGestureRecognizer: UITapGestureRecognizer {
    let tapMaxDelay: Double = 0.3 //anything below 0.3 may cause doubleTap to be inaccessible by many users

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        DispatchQueue.main.asyncAfter(deadline: .now() + tapMaxDelay) { [weak self] in
			if self?.state != UIGestureRecognizer.State.recognized {
				self?.state = UIGestureRecognizer.State.failed
            }
        }
    }
}
