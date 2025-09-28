//
//  StepState.swift
//  Shablonator
//
//  Created by Никита Долгов on 18.09.25.
//

import Foundation

final class StepState {
    private var values: [String: Any] = [:]
    
    func set(key: String, value: Any) {
        values[key] = value
    }
    
    func get(key: String) -> Any? {
        return values[key]
    }
    
    func getString(key: String) -> String? {
        return values[key] as? String
    }
    
    func getBool(key: String) -> Bool? {
        return values[key] as? Bool
    }
    
    func getInt(key: String) -> Int? {
        return values[key] as? Int
    }
    
    func getDate(key: String) -> Date? {
        return values[key] as? Date
    }
    
    func getAllValues() -> [String: Any] {
        return values
    }
}
