//
//  GRDBTemplateRepository.swift
//  Shablonator
//
//  Created by Никита Долгов on 13.10.25.
//

import Foundation
import GRDB
import Combine

final class GRDBTemplateRepository: TemplateRepositoryProtocol {

    private let dbQueue: DatabaseQueue

    // MARK: - Initialization
    init(dbQueue: DatabaseQueue = GRDBManager.shared.getDatabaseQueue()) {
        self.dbQueue = dbQueue
    }

    // MARK: - Базовые CRUD операции

    func getAllTemplates() -> AnyPublisher<[Template], Error> {
        return dbQueue.readPublisher { db -> [Template] in
            try Template.withStepCount().fetchAll(db) // ✅ ИСПРАВЛЕНО: используем withStepCount
        }
        .eraseToAnyPublisher()
    }

    func getTemplate(id: Int64) -> AnyPublisher<Template?, Error> {
        return dbQueue.readPublisher { db -> Template? in
            try Template.fetchOne(db, key: id)
        }
        .eraseToAnyPublisher()
    }

    func getTemplateWithSteps(id: Int64) -> AnyPublisher<Template?, Error> {
        return dbQueue.readPublisher { db -> Template? in
            guard var template = try Template.fetchOne(db, key: id) else {
                return nil
            }

            // Загружаем шаги с переменными
            let steps = try Step.forTemplate(id).fetchAll(db)
            template.steps = steps

            return template
        }
        .eraseToAnyPublisher()
    }

    func createTemplate(_ template: Template) -> AnyPublisher<Template, Error> {
        return dbQueue.writePublisher { db -> Template in
            var mutableTemplate = template
            try mutableTemplate.insert(db)
            return mutableTemplate
        }
        .eraseToAnyPublisher()
    }

    func updateTemplate(_ template: Template) -> AnyPublisher<Template, Error> {
        return dbQueue.writePublisher { db -> Template in
            var mutableTemplate = template
            try mutableTemplate.update(db)
            return mutableTemplate
        }
        .eraseToAnyPublisher()
    }

    func deleteTemplate(id: Int64) -> AnyPublisher<Void, Error> {
        return dbQueue.writePublisher { db in
            _ = try Template.deleteOne(db, key: id)
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Поиск и фильтрация

    func searchTemplates(query: String) -> AnyPublisher<[Template], Error> {
        return dbQueue.readPublisher { db -> [Template] in
            try Template.search(query: query).fetchAll(db)
        }
        .eraseToAnyPublisher()
    }

    func getActiveTemplates() -> AnyPublisher<[Template], Error> {
        return dbQueue.readPublisher { db -> [Template] in
            try Template.active().fetchAll(db)
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Работа с шагами

    func getStepsForTemplate(id: Int64) -> AnyPublisher<[Step], Error> {
        return dbQueue.readPublisher { db -> [Step] in
            try Step.forTemplate(id).fetchAll(db)
        }
        .eraseToAnyPublisher()
    }

    func addStepToTemplate(step: Step) -> AnyPublisher<Step, Error> {
        return dbQueue.writePublisher { db -> Step in
            var mutableStep = step
            try mutableStep.insert(db)
            return mutableStep
        }
        .eraseToAnyPublisher()
    }

    func updateStep(_ step: Step) -> AnyPublisher<Step, Error> {
        return dbQueue.writePublisher { db -> Step in
            var mutableStep = step
            try mutableStep.update(db)
            return mutableStep
        }
        .eraseToAnyPublisher()
    }

    func deleteStep(id: Int64) -> AnyPublisher<Void, Error> {
        return dbQueue.writePublisher { db in
            _ = try Step.deleteOne(db, key: id)
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Реактивные запросы для SwiftUI/Combine

    func observeAllTemplates() -> DatabasePublishers.Value<[Template]> {
        return ValueObservation
            .tracking(Template.withStepCount().fetchAll) // ✅ ИСПРАВЛЕНО
            .publisher(in: dbQueue)
    }

    func observeTemplate(id: Int64) -> DatabasePublishers.Value<Template?> {
        return ValueObservation
            .tracking { db in
                try Template.fetchOne(db, key: id)
            }
            .publisher(in: dbQueue)
    }

    func observeTemplateWithSteps(id: Int64) -> DatabasePublishers.Value<Template?> {
        return ValueObservation
            .tracking { db -> Template? in
                guard var template = try Template.fetchOne(db, key: id) else {
                    return nil
                }

                let steps = try Step.forTemplate(id).fetchAll(db)
                template.steps = steps

                return template
            }
            .publisher(in: dbQueue)
    }
}

// MARK: - Convenience Methods
extension GRDBTemplateRepository {

    /// Получить шаблоны по типу шагов
    func getTemplatesByStepKind(_ kind: Step.StepKind) -> AnyPublisher<[Template], Error> {
        return dbQueue.readPublisher { db -> [Template] in
            let sql = """
                SELECT DISTINCT t.* FROM template t
                INNER JOIN step s ON t.id = s.template_id
                WHERE s.kind = ?
                ORDER BY t.name
            """
            return try Template.fetchAll(db, sql: sql, arguments: [kind.rawValue])
        }
        .eraseToAnyPublisher()
    }

    /// Получить статистику использования шаблонов
    func getTemplateStats() -> AnyPublisher<[(Template, Int)], Error> {
        return dbQueue.readPublisher { db -> [(Template, Int)] in
            let sql = """
                SELECT t.*, COUNT(s.id) as step_count
                FROM template t
                LEFT JOIN step s ON t.id = s.template_id
                GROUP BY t.id, t.name, t.description, t.created_at, t.updated_at
                ORDER BY step_count DESC, t.name
            """

            var results: [(Template, Int)] = []
            let rows = try Row.fetchCursor(db, sql: sql)

            while let row = try rows.next() {
                let template = Template(row: row)
                let stepCount: Int = row["step_count"]
                results.append((template, stepCount))
            }

            return results
        }
        .eraseToAnyPublisher()
    }
}
