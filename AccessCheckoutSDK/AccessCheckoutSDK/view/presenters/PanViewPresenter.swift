import Foundation

class PanViewPresenter: NSObject, Presenter {
    private let validationFlow: PanValidationFlow
    private let validator: PanValidator
    private let panTextChangeHandler: PanTextChangeHandler
    private let panFormatter: PanFormatter

    init(_ validationFlow: PanValidationFlow, _ panValidator: PanValidator, panFormattingEnabled: Bool) {
        self.validationFlow = validationFlow
        self.validator = panValidator
        self.panTextChangeHandler = PanTextChangeHandler(panFormattingEnabled: panFormattingEnabled)
        self.panFormatter = PanFormatter(cardSpacingEnabled: panFormattingEnabled)
    }

    func onEditing(text: String) {
        validationFlow.validate(pan: text)
    }

    func onEditEnd() {
        validationFlow.notifyMerchantIfNotAlreadyNotified()
    }

    func canChangeText(with text: String) -> Bool {
        if text.isEmpty {
            return true
        }

        return validator.canValidate(text)
    }

    @objc
    func textFieldEditingChanged(_ textField: UITextField) {
        guard let text = textField.text else {
            return
        }

        let formattedPan = panFormatter.format(pan: text, brand: validationFlow.getCardBrand())
        if formattedPan != text {
            if let selectedTextRange = textField.selectedTextRange {
                let caretPosition = textField.offset(from: textField.beginningOfDocument, to: selectedTextRange.start)
                let newCaretPosition = findIndexOfNthDigit(text: formattedPan, nth: countNumberOfDigitsBeforeCaret(text, caretPosition))

                textField.text = formattedPan
                setCaretPosition(textField, newCaretPosition)
            } else {
                textField.text = formattedPan
            }
        }

        onEditing(text: formattedPan)
    }

    private func countNumberOfDigitsBeforeCaret(_ text: String, _ caretPosition: Int) -> Int {
        var numberOfDigits = 0
        for (index, character) in text.enumerated() {
            if index == caretPosition {
                break
            }

            if character.isNumber {
                numberOfDigits += 1
            }
        }

        return numberOfDigits
    }

    private func findIndexOfNthDigit(text: String, nth: Int) -> Int {
        var numberOfDigitsFound = 0
        var index = 0
        for character in text.enumerated() {
            if numberOfDigitsFound == nth {
                break
            } else if character.element.isNumber {
                numberOfDigitsFound += 1
            }

            index += 1
        }

        return index
    }

    private func setCaretPosition(_ textField: UITextField, _ newCaretPosition: Int) {
        DispatchQueue.main.async {
            if let newPosition = textField.position(from: textField.beginningOfDocument, offset: newCaretPosition) {
                textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
            }
        }
    }
}

extension PanViewPresenter: UITextFieldDelegate {
    public func textFieldDidEndEditing(_ textField: UITextField) {
        onEditEnd()
    }

    fileprivate func newRangeWithPreviousDigit(originalRange range: NSRange) -> NSRange {
        return NSRange(location: range.location - 1, length: range.length + 1)
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let digitsOnly = stripAllCharsButDigits(string)
        if digitsOnly.isEmpty, !string.isEmpty {
            setCaretPosition(textField, range.location)
            return false
        }

        let originalText = textField.text ?? ""
        let selection: NSRange
        let caretPosition: Int

        if isDeletingSpace(originalText: originalText, replacementString: string, selection: range) {
            selection = newRangeWithPreviousDigit(originalRange: range)
            caretPosition = range.location - 1
        } else {
            selection = range
            caretPosition = range.location
        }

        let resultingText = panTextChangeHandler.change(originalText: originalText,
                                                        textChange: digitsOnly,
                                                        usingSelection: selection,
                                                        brand: validationFlow.getCardBrand())

        if canChangeText(with: resultingText) {
            textField.text = resultingText
            onEditing(text: resultingText)

            let numberOfDigitsBeforeNewCaretPosition = countNumberOfDigitsBeforeCaret(originalText, caretPosition) + digitsOnly.count
            var newCaretPosition = findIndexOfNthDigit(text: resultingText, nth: numberOfDigitsBeforeNewCaretPosition)

            if isDeletingTextInFrontOfSpace(originalText: originalText, replacementString: string, caretPosition: caretPosition) {
                newCaretPosition = newCaretPosition + 1 // this is to ensure the caret is left after the space
            }
            setCaretPosition(textField, newCaretPosition)
            onEditEnd()
        } else {
            setCaretPosition(textField, range.location)
        }

        return false
    }

    private func isDeletingSpace(originalText: String, replacementString: String, selection: NSRange) -> Bool {
        return replacementString.isEmpty
            && selectionIsSpace(originalText, selectionStart: selection.lowerBound, selectionEnd: selection.upperBound)
    }

    private func isDeletingTextInFrontOfSpace(originalText: String, replacementString: String, caretPosition: Int) -> Bool {
        if !replacementString.isEmpty || caretPosition == 0 {
            return false
        }
        return selectionIsSpace(originalText, selectionStart: caretPosition - 1, selectionEnd: caretPosition)
    }

    private func selectionIsSpace(_ text: String, selectionStart: Int, selectionEnd: Int) -> Bool {
        let start = text.index(text.startIndex, offsetBy: selectionStart)
        let end = text.index(text.startIndex, offsetBy: selectionEnd)
        return text[start..<end] == " "
    }

    private func stripAllCharsButDigits(_ string: String) -> String {
        return string.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
    }
}
