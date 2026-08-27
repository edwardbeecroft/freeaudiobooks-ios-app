//
//  TypewriterTextView.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 11/02/2026.
//  Copyright © 2026 Kneady Technologies. All rights reserved.
//

import UIKit

class TypewriterTextView: UITextView {
    
    var addTimer: Timer?
    var unwindTimer: Timer?
    
    var suggestionText: String?
    var textAddedSoFar: String = ""
    var textRemovedSoFar: String = ""
    
    var animateTypingCompletion: (() -> Void)?
    var unwindTypingCompletion: (() -> Void)?
    var letterCompletion: (() -> Void)?
    
    private let letterInterval: CGFloat
    private let letterUnwindInterval: CGFloat
    private let insetText: Bool
    
    private var includeUnderscore: Bool = false
    
    init(letterInterval: CGFloat,
         letterUnwindInterval: CGFloat,
         insetText: Bool = false) {
        self.letterInterval = letterInterval
        self.letterUnwindInterval = letterUnwindInterval
        self.insetText = insetText
        super.init(frame: .zero, textContainer: nil)
        
        if insetText {
            textContainerInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        } else {
            textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        textContainer.lineFragmentPadding = 0
        isScrollEnabled = false
        isEditable = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        cancelAllTypingAnimations()
    }
    
    var heightConstraint: NSLayoutConstraint?
    var selfSize: Bool = false
    var selfSizeSideInsets: CGFloat = 0
    
    func animateTyping(suggestionText: String, includeUnderscore: Bool, selfSize: Bool, selfSizeSideInsets: CGFloat, completion: @escaping (() -> Void), letterCompletion: (() -> Void)?) {
        
        self.includeUnderscore = includeUnderscore
        self.animateTypingCompletion = completion
        
        if selfSize {
            self.letterCompletion = letterCompletion
            self.selfSize = selfSize
            self.selfSizeSideInsets = selfSizeSideInsets
            heightConstraint = heightAnchor.constraint(equalToConstant: 0)
            heightConstraint?.isActive = true
        }
        
        self.suggestionText = suggestionText
        
        self.text = ""
        self.textAddedSoFar = ""
        self.textRemovedSoFar = ""
        
        addTimer = Timer.scheduledTimer(withTimeInterval: letterInterval, repeats: true, block: { [weak self] timer in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.addNextLetter()
            }
        })
        RunLoop.main.add(addTimer!, forMode: .common)
    }
    
    @objc private func addNextLetter() {
        let remaining = suggestionText?.dropFirst(textAddedSoFar.count)
        if
            let remaining = remaining,
            let firstRemaining = remaining.first {
            DispatchQueue.main.async {
                if self.includeUnderscore {
                    self.text?.removeAll(where: { $0 == "_" })
                    var stringToAppend = String(firstRemaining)
                    // We don't want to add an underscore if GPT has finished it's answer
                    if remaining.count > 1 {
                        stringToAppend.append("_")
                    }
                    self.text?.append(stringToAppend)
                } else {
                    self.text?.append(firstRemaining)
                }
            }
            self.textAddedSoFar.append(firstRemaining)
            
            if selfSize {
                let requiredHeight = textAddedSoFar.heightWithConstrainedWidth(width: UIScreen.main.bounds.width - selfSizeSideInsets, font: font!)
                heightConstraint?.constant = requiredHeight + 6 //Random spacing otherwise height isn't enough for the font...classic hackery
                layoutIfNeeded()
                letterCompletion?()
            }
            
        } else {
            cancelAddTimer()
            
            // Clean up height constraint if using selfSize before calling completion
            if selfSize {
                heightConstraint?.isActive = false
                heightConstraint = nil
                selfSize = false
                
                // Force layout update to show full content
                setNeedsLayout()
                layoutIfNeeded()
                
                // Notify superview to update its layout
                superview?.setNeedsLayout()
                superview?.layoutIfNeeded()
            }
            
            animateTypingCompletion?()
        }
    }
    
    func unwindText(completion: @escaping (() -> Void)) {
        unwindTypingCompletion = completion
        
        unwindTimer = Timer.scheduledTimer(withTimeInterval: letterUnwindInterval, repeats: true, block: { [weak self] timer in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.removeLastLetter()
            }
        })
        RunLoop.main.add(unwindTimer!, forMode: .common)
    }
    
    @objc private func removeLastLetter() {
        let remaining = suggestionText?.dropLast(textRemovedSoFar.count)
        if let lastRemaining = remaining?.last {
            DispatchQueue.main.async {
                let textRemaining = self.text ?? ""
                if !textRemaining.isEmpty {
                    self.text?.removeLast(1)
                } else {
                    // This is a safety fallback for when the label disappears when someone
                    self.cancelUnwindTimer()
                    self.unwindTypingCompletion?()
                }
            }
            self.textRemovedSoFar.append(lastRemaining)
        } else {
            cancelUnwindTimer()
            unwindTypingCompletion?()
        }
    }
    
    func cancelAllTypingAnimations() {
        // This was causing a crash. Not sure it was really doing anything, anyway
        //text = ""
        cancelAddTimer()
        cancelUnwindTimer()
        animateTypingCompletion = nil
        unwindTypingCompletion = nil
        letterCompletion = nil
        heightConstraint?.isActive = false
        heightConstraint = nil
    }
    func cancelAddTimer() {
        addTimer?.invalidate()
        addTimer = nil
    }
    func cancelUnwindTimer() {
        unwindTimer?.invalidate()
        unwindTimer = nil
    }
}
