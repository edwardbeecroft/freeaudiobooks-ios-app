//
//  UIToolbar+Extensions.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 03/09/2020.
//  Copyright © 2020 Radically Better Ltd. All rights reserved.
//

import UIKit

struct Toolbars {
	static func getDoneToolbar(selector: Selector) -> UIToolbar {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
        applyAppearance(to: toolbar)
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let spaceButtonTwo = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: selector)
        
        let attributes = [NSAttributedString.Key.font : Fonts.semiBold15]
        doneButton.setTitleTextAttributes(attributes, for: .normal)
        doneButton.setTitleTextAttributes(attributes, for: .highlighted)
        doneButton.setTitleTextAttributes(attributes, for: .focused)
        
        toolbar.setItems([spaceButton, doneButton, spaceButtonTwo], animated: false)
        return toolbar
	}
    static func getInputToolbar(clearSelector: Selector, doneSelector: Selector) -> UIToolbar {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
        applyAppearance(to: toolbar)
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let clearButton = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: clearSelector)
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: doneSelector)
        
        [clearButton, doneButton].forEach {
            let attributes = [NSAttributedString.Key.font : Fonts.semiBold15]
            $0.setTitleTextAttributes(attributes, for: .normal)
            $0.setTitleTextAttributes(attributes, for: .highlighted)
            $0.setTitleTextAttributes(attributes, for: .focused)
        }
        
        toolbar.setItems([clearButton, spaceButton, doneButton], animated: false)
        return toolbar
    }

    private static func applyAppearance(to toolbar: UIToolbar) {
        toolbar.isTranslucent = false
        toolbar.barTintColor = Colours.chromeBackground
        toolbar.backgroundColor = Colours.chromeBackground
        toolbar.tintColor = Colours.textPrimary

        if #available(iOS 13.0, *) {
            let appearance = UIToolbarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = Colours.chromeBackground
            toolbar.standardAppearance = appearance
            toolbar.compactAppearance = appearance
            if #available(iOS 15.0, *) {
                toolbar.scrollEdgeAppearance = appearance
            }
        }
    }
}
