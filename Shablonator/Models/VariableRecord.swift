//
//  VariableRecord.swift
//  Shablonator
//
//  Created by Никита Долгов on 18.09.25.
//

import Foundation
import GRDB

struct VariableRecord: Codable, FetchableRecord, MutablePersistableRecord, Identifiable {
    var id: Int64?
    var stepId: Int64
    var name: String
    var type: String
    var defaultValue: String?
    var optionsJson: String?
    
    static let databaseTableName = "variable"
    
    enum CodingKeys: String, CodingKey {
        case id
        case stepId = "step_id"
        case name
        case type
        case defaultValue = "default_value"
        case optionsJson = "options_json"
    }
    
    // Добавляем didInsert для MutablePersistableRecord
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    func parseOptions() -> [String: Any]? {
        guard let jsonString = optionsJson,
              let data = jsonString.data(using: .utf8) else { return nil }
        
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}

