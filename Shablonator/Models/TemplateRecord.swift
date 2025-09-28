//
//  TemplateRecord.swift
//  Shablonator
//
//  Created by Никита Долгов on 18.09.25.
//


import GRDB

struct TemplateRecord: Codable, FetchableRecord, MutablePersistableRecord, Identifiable {
    var id: Int64?
    var userId: Int64
    var name: String
    var description: String?

    static let databaseTableName = "template"

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "userid"
        case name
        case description
    }

    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

