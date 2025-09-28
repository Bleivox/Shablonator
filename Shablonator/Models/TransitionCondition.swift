//
//  TransitionCondition.swift
//  Shablonator
//
//  Created by Никита Долгов on 18.09.25.
//

import Foundation

// Условие перехода
struct TransitionCondition {
    let key: String
    let operation: String // "==", "!=", "contains", etc.
    let expectedValue: Any
    
    func matches(state: StepState) -> Bool {
        guard let actualValue = state.get(key: key) else { return false }
        
        switch operation {
        case "==":
            // если expectedValue — "true"/"false", а фактическое значение Bool
            if let r = expectedValue as? String,
               let boolRight = Bool(r.lowercased()),
               let boolLeft = actualValue as? Bool {
                return boolLeft == boolRight
            }
            return isEqual(actualValue, expectedValue)
        case "!=":
            return !isEqual(actualValue, expectedValue)
        case "contains":
            if let actualString = actualValue as? String,
               let expectedString = expectedValue as? String {
                return actualString.localizedCaseInsensitiveContains(expectedString)
            }
            return false
        default:
            return false
        }
    }
    
    private func isEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        if let l = lhs as? String, let r = rhs as? String { return l == r }
        if let l = lhs as? Int, let r = rhs as? Int { return l == r }
        if let l = lhs as? Bool, let r = rhs as? Bool { return l == r }
        return false
    }
}
