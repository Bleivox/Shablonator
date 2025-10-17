//
//  Template.swift
//  Shablonator
//
//  Created by Никита Долгов on 10.10.25.
//

import Foundation
import GRDB

struct Template: Codable, Identifiable, Hashable {
    let id: Int64
    var name: String
    var description: String?
    let createdAt: Date
    var updatedAt: Date

    // Связанные данные (загружаются отдельно)
    var steps: [Step]?

    init(
        id: Int64 = 0,
        name: String,
        description: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Вычисляемые свойства
    var stepCount: Int {
        return steps?.count ?? 0
    }

    var hasWorkflow: Bool {
        return stepCount > 1
    }

    var displayStepCount: String {
        let count = stepCount
        if count == 0 {
            return "Нет шагов"
        } else if count == 1 {
            return "1 шаг"
        } else if count < 5 {
            return "\(count) шага"
        } else {
            return "\(count) шагов"
        }
    }

    var isComplete: Bool {
        guard let steps = steps else { return false }
        return steps.contains { $0.isStart } && steps.contains { $0.isTerminal }
    }
}

// MARK: - GRDB Record Conformance
extension Template: FetchableRecord, MutablePersistableRecord {

    /// Название таблицы в базе данных
    static let databaseTableName = "template"

    /// Связи с другими таблицами
    static let steps = hasMany(Step.self)

    /// Инициализация из строки базы данных
    init(row: Row) {
        id = row["id"]
        name = row["name"]
        description = row["description"]
        createdAt = row["created_at"]
        updatedAt = row["updated_at"]
    }

    /// Сохранение в базу данных
    func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["name"] = name
        container["description"] = description
        container["created_at"] = createdAt
        container["updated_at"] = updatedAt
    }

    /// ✅ ИСПРАВЛЕНО: Автоматическое обновление updated_at при сохранении
    mutating func willSave(_ db: Database) throws {
        updatedAt = Date()
    }
}

// MARK: - Database Queries
extension Template {

    /// ✅ ИСПРАВЛЕНО: Получить все шаблоны, отсортированные по имени
    static func allSorted() -> QueryInterfaceRequest<Template> {
        return Template.all().order(Column("name"))
    }

    /// Получить шаблон с загруженными шагами
    static func withSteps(id: Int64) -> QueryInterfaceRequest<Template> {
        return Template.filter(key: id)
            .including(all: Template.steps.order(Column("sort_hint")))
    }

    /// Поиск шаблонов по названию или описанию
    static func search(query: String) -> QueryInterfaceRequest<Template> {
        let searchPattern = "%\(query)%"
        return Template.filter(
            Column("name").like(searchPattern) ||
            Column("description").like(searchPattern)
        ).order(Column("name"))
    }

    /// ✅ ИСПРАВЛЕНО: Получить шаблоны с количеством шагов
    static func withStepCount() -> QueryInterfaceRequest<Template> {
        return Template.all()
            .annotated(with: Template.steps.count)
            .order(Column("name"))
    }

    /// Получить только активные шаблоны (с шагами)
    static func active() -> QueryInterfaceRequest<Template> {
        return Template.all()
            .having(Template.steps.count > 0)
            .order(Column("name"))
    }
}

// MARK: - Mock Data для разработки и тестирования
extension Template {
    static var mockData: [Template] {
        return [
            Template(
                id: 1,
                name: "Напоминание о приеме",
                description: "Стандартная последовательность напоминаний пациенту о предстоящем приеме"
            ),
            Template(
                id: 2,
                name: "После имплантации",
                description: "Контроль состояния пациента после установки имплантата"
            ),
            Template(
                id: 3,
                name: "Профилактический осмотр",
                description: "Приглашение на плановый профилактический осмотр"
            ),
            Template(
                id: 4,
                name: "Лечение кариеса",
                description: "Процедуры до, во время и после лечения кариеса"
            ),
            Template(
                id: 5,
                name: "Отбеливание зубов",
                description: "Подготовка и уход после процедуры отбеливания"
            )
        ]
    }
}
