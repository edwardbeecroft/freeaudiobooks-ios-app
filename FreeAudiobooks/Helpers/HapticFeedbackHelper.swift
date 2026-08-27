//
//  HapticFeedbackHelper.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 02/01/2019.
//  Copyright © 2019 Ed Beecroft. All rights reserved.
//

import UIKit

/**
https://developer.apple.com/documentation/uikit/uifeedbackgenerator
https://developer.apple.com/documentation/uikit/uiselectionfeedbackgenerator

Note that to save power the haptic engine only stays warmed up for a few seconds.
If it's not warmed up, no haptic feedback will occur.
*/
class HapticFeedbackHelper {
    
    // MARK: - Shared instance & initialiser
    
    static let shared = HapticFeedbackHelper()
    private init() {}
    
    // MARK: - Properties
    
    private let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
    private let notificationFeedbackGenerator = UINotificationFeedbackGenerator()

}

extension HapticFeedbackHelper {
    func triggerLightImpactFeedback() {
        lightImpactFeedbackGenerator.prepare()
        lightImpactFeedbackGenerator.impactOccurred()
    }
    func prepareLightFeedbackGenerator() {
        lightImpactFeedbackGenerator.prepare()
    }
}

extension HapticFeedbackHelper {
    func prepareSuccessFeedbackGenerator() {
        notificationFeedbackGenerator.prepare()
    }
    func triggerSuccessHaptic() {
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.success)
    }
}

extension HapticFeedbackHelper {
    func prepareSelectionFeedbackGenerator() {
        selectionFeedbackGenerator.prepare()
    }
    func triggerSelectionChangeHaptic() {
        selectionFeedbackGenerator.prepare()
        selectionFeedbackGenerator.selectionChanged()
    }
}
