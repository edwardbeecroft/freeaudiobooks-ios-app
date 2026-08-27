//
//  UIScrollView+Extensions.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 08/08/2023.
//  Copyright © 2023 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

extension UIScrollView {
    func scrollToTop(animated: Bool) {
        let desiredOffset = CGPoint(x: 0, y: -contentInset.top)
        setContentOffset(desiredOffset, animated: animated)
   }
}

extension UIScrollView {
    var maxContentOffset: CGPoint {
        return CGPoint(
          x: contentSize.width - bounds.width + contentInset.right,
          y: contentSize.height - bounds.height + contentInset.bottom)
      }
}
