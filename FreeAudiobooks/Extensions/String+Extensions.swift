//
//  String+Extensions.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 06/01/2019.
//  Copyright © 2019 Ed Beecroft. All rights reserved.
//

import UIKit
import CommonCrypto
import Foundation

extension String {
	func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
		let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
		let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: font], context: nil)
        return boundingBox.height
    }
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
}

extension NSMutableAttributedString {

	@discardableResult func normal(_ text: String, size: CGFloat) -> NSMutableAttributedString {
		let attrs: [NSAttributedString.Key: Any] = [.font: Fonts.mediumWithSize(size)]
		let normal = NSAttributedString(string: text, attributes: attrs)
		append(normal)
		
		return self
	}
	
	@discardableResult func bold(_ text: String, size: CGFloat) -> NSMutableAttributedString {
		let attrs: [NSAttributedString.Key: Any] = [.font: Fonts.semiBoldWithSize(size)]
		let boldString = NSMutableAttributedString(string:text, attributes: attrs)
		append(boldString)
		
		return self
	}
	
	@discardableResult func stringWith(_ text: String,
									   font: UIFont,
									   color: UIColor = Colours.grey100,
									   underline: Bool = false,
									   indent: Bool = false) -> NSMutableAttributedString {
		var attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
		if underline {
			attrs[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.single.rawValue
			attrs[NSAttributedString.Key.underlineColor] = color.withAlphaComponent(0.6)
		}
		if indent {
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.firstLineHeadIndent = 10
			paragraphStyle.headIndent = 10
			attrs[NSAttributedString.Key.paragraphStyle] = paragraphStyle
		}
		
		let normal = NSAttributedString(string: text, attributes: attrs)
		append(normal)
		
		return self
	}
}

extension String {
    func isValidEmailAddress() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
}

extension String {
    func lowercasedFirstLetter() -> String {
        return prefix(1).lowercased() + dropFirst()
     }
 }

extension String {
    func uppercasedFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
     }
 }

extension String {
    func wordCount() -> Int {
        var count = 0
        enumerateSubstrings(in: startIndex..<endIndex, options: [.byWords, .localized]) { _, _, _, _ in
            count += 1
        }
        return count
    }
}

extension String {
    func split(by length: Int) -> [String] {
        var startIndex = self.startIndex
        var results = [Substring]()

        while startIndex < self.endIndex {
            let endIndex = self.index(startIndex, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            results.append(self[startIndex..<endIndex])
            startIndex = endIndex
        }

        return results.map { String($0) }
    }
}

extension String {
    func splitByWordLength(_ length: Int, seperator: String) -> [String] {
        var result = [String]()
        var collectedWords = [String]()
        collectedWords.reserveCapacity(length)
        var count = 0
        let words = self.components(separatedBy: " ")

        for word in words {
            count += word.count + 1 //add 1 to include space
            if (count > length) {
                // Reached the desired length

                result.append(collectedWords.map { String($0) }.joined(separator: seperator) )
                collectedWords.removeAll(keepingCapacity: true)

                count = word.count
                collectedWords.append(word)
            } else {
                collectedWords.append(word)
            }
        }

        // Append the remainder
        if !collectedWords.isEmpty {
            result.append(collectedWords.map { String($0) }.joined(separator: seperator))
        }

        return result
    }
}

extension String {
    func splitByLine() -> [String] {
        let lines = components(separatedBy: "\n")
        let maxCharactersPerPage: Int = 10000
        var pages = [String]()
        var page = ""
        for line in lines {
            let wordsInLine = line.components(separatedBy: " ")
            for word in wordsInLine {
                if page.count + word.count + 1 > maxCharactersPerPage {
                    pages.append(page)
                    page = word + " "
                } else {
                    page += word + " "
                }
            }
            if !page.isEmpty {
                page += "\n"
            }
        }
        
        pages.append(page)
        return pages
    }
}

extension String {
    // This was obscenely slow
    func splitBySentence() -> [String] {
        let sentences = components(separatedBy: ".") // first split
            .flatMap { [".", $0] } // add the separator after each split
            .dropLast() // remove the last separator added
        
        let maxWordsPerPage: Int = 3000
        let wordsPerSentence: Int = 20
        let sentencesPerPage = maxWordsPerPage / wordsPerSentence
        
        
        var finalSections = [String]()
        var sectionToAdd = String()
        for sentence in sentences {
            if sectionToAdd.wordCount() < maxWordsPerPage {
                sectionToAdd.append(sentence)
            } else {
                finalSections.append(sectionToAdd)
                sectionToAdd = sentence
            }
        }
        finalSections.append(sectionToAdd)
        return finalSections
    }
}

extension String {
    func removingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}
