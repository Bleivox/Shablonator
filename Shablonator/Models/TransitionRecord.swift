//
//  TransitionRecord.swift
//  Shablonator
//
//  Created by Никита Долгов on 18.09.25.
//

import Foundation
import GRDB

struct TransitionRecord: Codable, FetchableRecord, MutablePersistableRecord, Identifiable {
    var id: Int64?
    var fromStepId: Int64
    var toStepId: Int64
    var label: String?
    var conditionJson: String?
    
    static let databaseTableName = "transition"
    
    enum CodingKeys: String, CodingKey {
        case id
        case fromStepId = "from_step_id"
        case toStepId = "to_step_id"
        case label
        case conditionJson = "condition_json"
    }
    
    // Добавляем didInsert для MutablePersistableRecord
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    // Парсинг условий из JSON
    func parseConditions() -> [[TransitionCondition]] {
        guard let jsonString = conditionJson,
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let ifExpr = json["if"] as? String
        else { return [] }

        // Разбиваем по OR на группы, каждая группа — набор условий, объединённых AND
        let orGroups = ifExpr.components(separatedBy: "||")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        var result: [[TransitionCondition]] = []
        for group in orGroups {
            // поддерживаем только “key==value” в каждой группе
            if let range = group.range(of: "==") {
                let key = String(group[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                var value = String(group[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                // снимаем кавычки, если есть
                value = value.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                result.append([TransitionCondition(key: key, operation: "==", expectedValue: value)])
            }
        }
        return result
    }
}

