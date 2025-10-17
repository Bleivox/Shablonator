//
//  Transition.swift
//  Shablonator
//
//  Created by Никита Долгов on 13.10.25.
//

import Foundation
import GRDB

struct Transition: Codable, Identifiable, Hashable {
    let id: Int64
    let fromStepId: Int64
    let toStepId: Int64
    var label: String?              // "Да", "Нет", "Следующий", "Через 3 дня"
    var conditionJson: String?      // JSON с условиями выполнения перехода

    init(
        id: Int64 = 0,
        fromStepId: Int64,
        toStepId: Int64,
        label: String? = nil,
        conditionJson: String? = nil
    ) {
        self.id = id
        self.fromStepId = fromStepId
        self.toStepId = toStepId
        self.label = label
        self.conditionJson = conditionJson
    }

    // Computed properties
    var displayLabel: String {
        return label ?? "Переход"
    }

    var hasCondition: Bool {
        return conditionJson != nil && !conditionJson!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var condition: TransitionCondition? {
        guard let conditionJson = conditionJson,
              let data = conditionJson.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(TransitionCondition.self, from: data)
    }

    var isAutomatic: Bool {
        return condition?.type == .always || condition?.type == .delay
    }

    var requiresUserAction: Bool {
        return condition?.type == .manual || condition?.type == .userInput
    }
}

// MARK: - GRDB Record Conformance
extension Transition: FetchableRecord, MutablePersistableRecord {

    static let databaseTableName = "transition"

    // Связи со шагами
    static let fromStep = belongsTo(Step.self, using: ForeignKey(["from_step_id"]))
    static let toStep = belongsTo(Step.self, using: ForeignKey(["to_step_id"]))

    init(row: Row) {
        id = row["id"]
        fromStepId = row["from_step_id"]
        toStepId = row["to_step_id"]
        label = row["label"]
        conditionJson = row["condition_json"]
    }

    func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["from_step_id"] = fromStepId
        container["to_step_id"] = toStepId
        container["label"] = label
        container["condition_json"] = conditionJson
    }
}

// MARK: - Database Queries
extension Transition {

    /// Получить переходы от определенного шага
    static func fromStep(_ stepId: Int64) -> QueryInterfaceRequest<Transition> {
        return Transition.filter(Column("from_step_id") == stepId)
            .order(Column("label"))
    }

    /// Получить переходы к определенному шагу
    static func toStep(_ stepId: Int64) -> QueryInterfaceRequest<Transition> {
        return Transition.filter(Column("to_step_id") == stepId)
            .order(Column("label"))
    }

    /// Получить автоматические переходы
    static func automatic() -> QueryInterfaceRequest<Transition> {
        return Transition.filter(Column("condition_json").like("%\"always\"%") ||
                               Column("condition_json").like("%\"delay\"%"))
    }

    /// Получить переходы, требующие пользовательского действия
    static func manual() -> QueryInterfaceRequest<Transition> {
        return Transition.filter(Column("condition_json").like("%\"manual\"%") ||
                               Column("condition_json").like("%\"userInput\"%"))
    }
}

// MARK: - Transition Condition Model
struct TransitionCondition: Codable {
    var type: ConditionType
    var variable: String?           // Имя переменной для проверки
    var operatorType: ConditionOperator? // ✅ ИСПРАВЛЕНО: operatorType вместо operator
    var value: String?              // Значение для сравнения
    var delay: TimeInterval?        // Задержка в секундах
    var description: String?        // Описание условия

    enum ConditionType: String, Codable {
        case always = "always"          // Всегда выполняется
        case delay = "delay"           // После задержки
        case variable = "variable"      // По значению переменной
        case userInput = "userInput"   // Ввод пользователя
        case manual = "manual"         // Ручное подтверждение
        case time = "time"             // По времени
        case date = "date"             // По дате

        var displayName: String {
            switch self {
            case .always: return "Всегда"
            case .delay: return "После задержки"
            case .variable: return "По переменной"
            case .userInput: return "Ввод пользователя"
            case .manual: return "Вручную"
            case .time: return "По времени"
            case .date: return "По дате"
            }
        }
    }

    enum ConditionOperator: String, Codable {
        case equals = "equals"
        case notEquals = "not_equals"
        case greater = "greater"
        case less = "less"
        case greaterOrEqual = "greater_or_equal"
        case lessOrEqual = "less_or_equal"
        case contains = "contains"
        case notContains = "not_contains"
        case isEmpty = "is_empty"
        case isNotEmpty = "is_not_empty"

        var displayName: String {
            switch self {
            case .equals: return "равно"
            case .notEquals: return "не равно"
            case .greater: return "больше"
            case .less: return "меньше"
            case .greaterOrEqual: return "больше или равно"
            case .lessOrEqual: return "меньше или равно"
            case .contains: return "содержит"
            case .notContains: return "не содержит"
            case .isEmpty: return "пустое"
            case .isNotEmpty: return "не пустое"
            }
        }
    }

    // Computed properties
    var displayDescription: String {
        switch type {
        case .always:
            return "Выполняется всегда"
        case .delay:
            let minutes = (delay ?? 0) / 60
            return "Задержка \(Int(minutes)) мин"
        case .variable:
            guard let variable = variable,
                  let operatorType = operatorType else { // ✅ ИСПРАВЛЕНО
                return "Условие по переменной"
            }
            let valueText = value ?? "значению"
            return "\(variable) \(operatorType.displayName) \(valueText)"
        case .userInput:
            return "Ожидает ввода пользователя"
        case .manual:
            return "Ручное подтверждение"
        case .time, .date:
            return "По времени/дате"
        }
    }
}

// MARK: - Common Transitions для стоматологии
extension Transition {

    /// Создать простой автоматический переход
    static func createAutomatic(from fromStepId: Int64, to toStepId: Int64, label: String? = nil) -> Transition {
        let condition = TransitionCondition(type: .always)
        let conditionData = try? JSONEncoder().encode(condition)
        let conditionJson = conditionData.flatMap { String(data: $0, encoding: .utf8) }

        return Transition(
            fromStepId: fromStepId,
            toStepId: toStepId,
            label: label ?? "Следующий шаг",
            conditionJson: conditionJson
        )
    }

    /// Создать переход с задержкой
    static func createDelayed(from fromStepId: Int64, to toStepId: Int64, delayMinutes: Int, label: String? = nil) -> Transition {
        let condition = TransitionCondition(
            type: .delay,
            delay: TimeInterval(delayMinutes * 60),
            description: "Задержка \(delayMinutes) минут"
        )
        let conditionData = try? JSONEncoder().encode(condition)
        let conditionJson = conditionData.flatMap { String(data: $0, encoding: .utf8) }

        return Transition(
            fromStepId: fromStepId,
            toStepId: toStepId,
            label: label ?? "Через \(delayMinutes) мин",
            conditionJson: conditionJson
        )
    }

    /// Создать условный переход по переменной
    static func createConditional(
        from fromStepId: Int64,
        to toStepId: Int64,
        variable: String,
        operatorType: TransitionCondition.ConditionOperator, // ✅ ИСПРАВЛЕНО
        value: String,
        label: String? = nil
    ) -> Transition {
        let condition = TransitionCondition(
            type: .variable,
            variable: variable,
            operatorType: operatorType, // ✅ ИСПРАВЛЕНО
            value: value
        )
        let conditionData = try? JSONEncoder().encode(condition)
        let conditionJson = conditionData.flatMap { String(data: $0, encoding: .utf8) }

        return Transition(
            fromStepId: fromStepId,
            toStepId: toStepId,
            label: label ?? "Если \(variable)",
            conditionJson: conditionJson
        )
    }

    /// Создать ручной переход
    static func createManual(from fromStepId: Int64, to toStepId: Int64, label: String) -> Transition {
        let condition = TransitionCondition(type: .manual)
        let conditionData = try? JSONEncoder().encode(condition)
        let conditionJson = conditionData.flatMap { String(data: $0, encoding: .utf8) }

        return Transition(
            fromStepId: fromStepId,
            toStepId: toStepId,
            label: label,
            conditionJson: conditionJson
        )
    }
}
