//
//  TemplateRepository.swift
//  Shablonator
//
//  Created by Никита Долгов on 18.09.25.
//

import GRDB
import Foundation

final class TemplateRepository {
    private let dbq = AppDatabase.shared.dbQueue

    func templatesWithStepCount(userId: Int64) throws -> [(TemplateRecord, Int)] {
        try dbq.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT t.*, COUNT(s.id) AS step_count
                FROM template t
                LEFT JOIN step s ON s.template_id = t.id
                WHERE t.userid = ?
                GROUP BY t.id
                ORDER BY t.updated_at DESC
            """, arguments: [userId])

            return try rows.map { row in
                let rec = try TemplateRecord(row: row)
                // ВАЖНО: типизированное чтение числа
                let count = (row["step_count"] as Int64?).map(Int.init) ?? 0
                return (rec, count)
            }
        }
    }

    func steps(for templateId: Int64) throws -> [StepRecord] {
        try dbq.read { db in
            try StepRecord
                .filter(Column("template_id") == templateId)
                .order(Column("sort_hint"))
                .fetchAll(db)
        }
    }

    func createTemplate(userId: Int64, name: String, description: String?) throws -> Int64 {
        try dbq.write { db in
            let sql = """
            INSERT INTO template (userid, name, description)
            VALUES (?, ?, ?)
            RETURNING id
            """
            guard let newId = try Int64.fetchOne(db, sql: sql, arguments: [userId, name, description]) else {
                throw NSError(domain: "DB", code: -1, userInfo: [NSLocalizedDescriptionKey: "RETURNING id failed"])
            }
            return newId
        }
    }
    
    func createStep(templateId: Int64, title: String, content: String?, kind: String?, sortHint: Int) throws {
        try dbq.write { db in
            var step = StepRecord(
                id: nil,
                templateId: templateId,
                title: title,
                content: content,
                message: nil,
                kind: kind,
                isStart: sortHint == 0, // Первый шаг - стартовый
                isTerminal: false,
                sortHint: sortHint
            )
            try step.insert(db)
        }
    }





    func deleteTemplate(id: Int64) throws {
        try dbq.write { db in
            try db.execute(sql: "DELETE FROM template WHERE id = ?", arguments: [id])
        }
    }
}

extension TemplateRepository {
    // Запись всего шаблона одной транзакцией, маппинг localId -> realId
    func createFromBuilder(_ state: BuilderState) throws -> Int64 {
        try dbq.write { db in
            try db.execute(
                sql: "INSERT INTO template (userid, name, description) VALUES (?, ?, ?)",
                arguments: [state.userId, state.name, state.description]
            )
            let templateId = db.lastInsertedRowID

            var idMap: [Int64: Int64] = [:]
            for s in state.steps.sorted(by: { $0.sortHint < $1.sortHint }) {
                try db.execute(sql: """
                    INSERT INTO step (template_id, title, kind, is_start, is_terminal, sort_hint)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, arguments: [templateId, s.title, s.kind, s.isStart ? 1 : 0, s.isTerminal ? 1 : 0, s.sortHint])
                idMap[s.localId] = db.lastInsertedRowID
            }

            for v in state.variables {
                guard let realStepId = idMap[v.stepLocalId] else { continue }
                try db.execute(sql: """
                    INSERT INTO variable (step_id, name, type, default_value, options_json)
                    VALUES (?, ?, ?, ?, ?)
                """, arguments: [realStepId, v.name, v.type, v.defaultValue, v.optionsJson])
            }

            for t in state.transitions {
                guard let fromId = idMap[t.fromLocalId], let toId = idMap[t.toLocalId] else { continue }
                try db.execute(sql: """
                    INSERT INTO transition (from_step_id, to_step_id, label, condition_json)
                    VALUES (?, ?, ?, ?)
                """, arguments: [fromId, toId, t.label, t.conditionJson])
            }

            return templateId
        }
    }
}
