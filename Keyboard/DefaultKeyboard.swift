//
//  DefaultKeyboard.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/10/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import Foundation

func languageSpecificKeyboard() -> Keyboard?
{
    if let path = NSBundle.mainBundle().pathForResource("EnglishQWERTY", ofType: "json")
    {
        if !NSFileManager().fileExistsAtPath(path) {
            NSLog("File does not exist at \(path)")
            return nil
        }
        
        if let jsonData = NSData(contentsOfFile: path)
        {
            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(jsonData, options:NSJSONReadingOptions(rawValue: 0))
                
                guard let JSONDictionary: NSDictionary = JSON as? NSDictionary else {
                    NSLog("Not a Dictionary")
                    return nil
                }
                
                /*
                
                guard let keyboardName = JSONDictionary["keyboardName"] as? String else {
                debugMsg("Could not find 'keyboardName' element on root")
                return nil
                }
                
                */
                
                guard let pages = JSONDictionary["pages"] as? NSArray else {
                    NSLog("Could not find 'pages' array in root")
                    return nil
                }
                
                let newKeyboard = Keyboard()
                
                for page in pages {
                    
                    if let pageDict = page as? NSDictionary {
                        guard let pageIndex = pageDict["pageIndex"] as? Int else {
                            NSLog("Did not find 'pageIndex' attribute")
                            return nil
                        }
                        
                        guard let rows = pageDict["rows"] as? NSArray else {
                            NSLog("Could not find 'rows' array in root")
                            return nil
                        }
                        
                        for row in rows {
                            if let rowDict = row as? NSDictionary {
                                
                                guard let rowIndex = rowDict["rowIndex"] as? Int else {
                                    NSLog("Could not find 'rowIndex' attribute")
                                    return nil
                                }
                                
                                guard let keys = rowDict["keys"] as? NSArray else {
                                    NSLog("Could not find 'keys' array on root")
                                    return nil
                                }
                                
                                // HACKHACK Splice in the shift key
                                if rowIndex == 2 {
                                    let keyModel = Key(.Shift)
                                    
                                    newKeyboard.addKey(keyModel, row: rowIndex, page: pageIndex)
                                }
                                
                                for oneKey in keys {
                                    if let oneKeyRecord = oneKey as? NSDictionary {
                                        if let keyLabel = oneKeyRecord["label"] as? String {
                                            let keyModel = Key(.Character)
                                            keyModel.setLetter(keyLabel)
                                            keyModel.isTopRow = rowIndex == 0
                                            
                                            newKeyboard.addKey(keyModel, row: rowIndex, page: pageIndex)
                                        }
                                        
                                        // TODO store the ambiguous key values as well as the key label
                                        
                                    }
                                }
                            }
                        }
                    }
                }
                
                
                newKeyboard.addKey(Key(.Backspace), row: 2, page: 0)
                
                addNumericPage(newKeyboard)
                addSymbolsPage(newKeyboard)

                return newKeyboard
                
            }
            catch let JSONError as NSError {
                NSLog("JSONError exception\n\(JSONError)")
                return nil
            }
            catch {
                NSLog("Some other error occurred")
                return nil
            }
        }
    }
    
    return nil
}


func addNumericPage(defaultKeyboard: Keyboard)
{
    AddSpecialCharacters(defaultKeyboard, characters: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"], row: 0, page: 1)
    AddSpecialCharacters(defaultKeyboard, characters: ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""], row: 1, page: 1)

    let keyModeChangeSpecialCharacters = Key(.ModeChange)
    keyModeChangeSpecialCharacters.uppercaseKeyCap = "#+="
    keyModeChangeSpecialCharacters.toMode = 2
    defaultKeyboard.addKey(keyModeChangeSpecialCharacters, row: 2, page: 1)

    AddSpecialCharacters(defaultKeyboard, characters: [".", ",", "?", "!", "'"], row: 2, page: 1)

    defaultKeyboard.addKey(Key(.Backspace), row: 2, page: 1)
    
    addDefaultBottomRowKeys(defaultKeyboard, modeChange: Key.ModeChangeLettersKey(), pageNumber: 1)

}

func addSymbolsPage(defaultKeyboard: Keyboard)
{
    AddSpecialCharacters(defaultKeyboard, characters: ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="], row: 0, page: 2)
    AddSpecialCharacters(defaultKeyboard, characters: ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"], row: 1, page: 2)

    defaultKeyboard.addKey(Key.ModeChangeNumbersKey(), row: 2, page: 2)

    AddSpecialCharacters(defaultKeyboard, characters: [".", ",", "?", "!", "'"], row: 2, page: 2)

    defaultKeyboard.addKey(Key(.Backspace), row: 2, page: 2)

    addDefaultBottomRowKeys(defaultKeyboard, modeChange: Key.ModeChangeLettersKey(), pageNumber: 2)
    
}

func addDefaultBottomRowKeys(defaultKeyboard: Keyboard, modeChange: Key, pageNumber: Int)
{
    defaultKeyboard.addKey(modeChange, row: 3, page: pageNumber)
    defaultKeyboard.addKey(Key.NextKbdKey(), row: 3, page: pageNumber)
    defaultKeyboard.addKey(Key(.Settings), row: 3, page: pageNumber)
    defaultKeyboard.addKey(Key.SpaceKey(), row: 3, page: pageNumber)
    defaultKeyboard.addKey(Key.ReturnKey(), row: 3, page: pageNumber)
}

func defaultKeyboard(keyboardType:UIKeyboardType) -> Keyboard
{
	switch keyboardType
    {
    case .NumberPad, .DecimalPad:
        return defaultKeyboardNumber()
        
    case .EmailAddress:
        return defaultKeyboardEmail()
        
    case .URL, .WebSearch:
        return defaultKeyboardURL()
        
    default:
        return defaultLanguageSpecificKeyboard()
    }
}

// FailSafeKeyboardDefault.
// If we ever fail to read in a language-specific JSON keyboard definition, revert to
// a QWERTY layout using hard-coded lists of key values. We MUST show something to the user at all costs.
func FailSafeKeyboard() -> Keyboard {
    let defaultKeyboard = Keyboard()
    
    AddCharacters(defaultKeyboard, characters: ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"], row: 0, page: 0)
    AddCharacters(defaultKeyboard, characters: ["A", "S", "D", "F", "G", "H", "J", "K", "L"], row: 1, page: 0)
	
    let keyModel = Key(.Shift)
    defaultKeyboard.addKey(keyModel, row: 2, page: 0)

    AddCharacters(defaultKeyboard, characters: ["Z", "X", "C", "V", "B", "N", "M"], row: 2, page: 0)
    
    addDefaultBottomRowKeys(defaultKeyboard, modeChange: Key.ModeChangeNumbersKey(), pageNumber: 0)
    addNumericPage(defaultKeyboard)
    addSymbolsPage(defaultKeyboard)
    
    return defaultKeyboard
}

// defaultLanguageSpecificKeyboard.
// Create a language-specific keyboard. Note that for now the only part that varies by language is the alpha page.
//
// If we fail to create the alpha layer, default to a QWERTY layout.
func defaultLanguageSpecificKeyboard() -> Keyboard
{
    if let defaultKeyboard = languageSpecificKeyboard() {
        addDefaultBottomRowKeys(defaultKeyboard, modeChange: Key.ModeChangeNumbersKey(), pageNumber: 0)
        
        return defaultKeyboard
    }
    else {
        return FailSafeKeyboard()
    }
}

// The main alpha page for email mode has
// a special bottom row with an at sign and period between the space bar and enter key
func addEmailBottomRowKeys(defaultKeyboard: Keyboard)
{
    defaultKeyboard.addKey(Key.ModeChangeNumbersKey(), row: 3, page: 0)
    defaultKeyboard.addKey(Key.NextKbdKey(), row: 3, page: 0)
    defaultKeyboard.addKey(Key(.Settings), row: 3, page: 0)
    defaultKeyboard.addKey(Key.SpaceKey(), row: 3, page: 0)
    
    defaultKeyboard.addKey(Key.AtKey(), row: 3, page: 0)
    defaultKeyboard.addKey(Key.PeriodKey(), row: 3, page: 0)

    defaultKeyboard.addKey(Key.ReturnKey(), row: 3, page: 0)
}

func defaultKeyboardEmail() -> Keyboard {
    if let defaultKeyboard = languageSpecificKeyboard() {
        
        addEmailBottomRowKeys(defaultKeyboard)
        
        return defaultKeyboard
    }
    else {
        return FailSafeKeyboard()
    }
    
}

// The main alpha page for URL and Web Search modes has
// a special bottom row with a slash and period between the space bar and enter key
func addURLBottomRowKeys(defaultKeyboard: Keyboard)
{
    defaultKeyboard.addKey(Key.ModeChangeNumbersKey(), row: 3, page: 0)
    defaultKeyboard.addKey(Key.NextKbdKey(), row: 3, page: 0)
    defaultKeyboard.addKey(Key(.Settings), row: 3, page: 0)
    defaultKeyboard.addKey(Key.SpaceKey(), row: 3, page: 0)
    
    defaultKeyboard.addKey(Key.SlashKey(), row: 3, page: 0)
    defaultKeyboard.addKey(Key.PeriodKey(), row: 3, page: 0)
    
    defaultKeyboard.addKey(Key.ReturnKey(), row: 3, page: 0)
}

func defaultKeyboardURL() -> Keyboard {
    if let defaultKeyboard = languageSpecificKeyboard() {
        
        addURLBottomRowKeys(defaultKeyboard)
        
        return defaultKeyboard
    }
    else {
        return FailSafeKeyboard()
    }

}

func defaultKeyboardNumber() -> Keyboard {
	let defaultKeyboard = Keyboard()
    
    AddCharacters(defaultKeyboard, characters: ["1", "2", "3", "."], row: 0, page: 0)
    AddCharacters(defaultKeyboard, characters: ["4", "5", "6", ","], row: 1, page: 0)
    AddCharacters(defaultKeyboard, characters: ["7", "8", "9", "-"], row: 2, page: 0)
    AddCharacters(defaultKeyboard, characters: ["00","0"], row: 3, page: 0)
		
    defaultKeyboard.addKey(Key.NextKbdKey(), row: 3, page: 0)
	defaultKeyboard.addKey(Key(.Backspace), row: 3, page: 0)

    return defaultKeyboard
}

func AddCharsHelper(defaultKeyboard: Keyboard, characters: [String], row: Int, page: Int, keyType: Key.KeyType)
{
    for c in characters {
        let key = Key(keyType)
        key.setLetter(c)
        key.isTopRow = row == 0
        
        defaultKeyboard.addKey(key, row: row, page: page)
    }
}

func AddSpecialCharacters (defaultKeyboard: Keyboard, characters: [String], row: Int, page: Int)
{
    AddCharsHelper(defaultKeyboard, characters: characters, row: row, page: page, keyType: .SpecialCharacter)
}

func AddCharacters (defaultKeyboard: Keyboard, characters: [String], row: Int, page: Int)
{
    AddCharsHelper(defaultKeyboard, characters: characters, row: row, page: page, keyType: .Character)
}

