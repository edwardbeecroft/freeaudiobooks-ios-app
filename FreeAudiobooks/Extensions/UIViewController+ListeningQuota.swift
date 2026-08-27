//
//  UIViewController+ListeningQuota.swift
//  FreeAudiobooks
//
//  Created by Codex on 20/05/2026.
//  Copyright © 2026 FreeAudiobooks Technologies. All rights reserved.
//

import UIKit

extension UIViewController {
    func presentListeningQuotaSheet() {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
        let sheet = ListeningQuotaSheetVC()
        sheet.onUnlocked = {
            NotificationCenter.default.post(name: .didUpdateSubscriberStatus, object: nil)
        }
        present(sheet, animated: true)
    }

    func presentListeningQuotaDepletedSheet(for metadata: ReadableContentMetadata, onUnlocked: (() -> Void)? = nil) {
        HapticFeedbackHelper.shared.triggerLightImpactFeedback()
        let sheet = ListeningQuotaDepletedSheetVC(metadata: metadata)
        sheet.onUnlocked = {
            NotificationCenter.default.post(name: .didUpdateSubscriberStatus, object: nil)
            onUnlocked?()
        }
        present(sheet, animated: true)
    }
}
