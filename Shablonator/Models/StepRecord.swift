//
//  StepRecord.swift
//  Shablonator
//
//  Created by Никита Долгов on 18.09.25.
//

import Foundation
import GRDB

struct StepRecord: Codable, FetchableRecord, MutablePersistableRecord, Identifiable {
    var id: Int64?
    var templateId: Int64
    var title: String
    var content: String?
    var message: String?
    var kind: String?
    var isStart: Bool
    var isTerminal: Bool
    var sortHint: Int

    static let databaseTableName = "step"

    // соответствие колонок snake_case
    enum CodingKeys: String, CodingKey {
        case id
        case templateId = "template_id"
        case title
        case content
        case message
        case kind
        case isStart = "is_start"
        case isTerminal = "is_terminal"
        case sortHint = "sort_hint"
    }

    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
