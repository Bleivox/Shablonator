//
//  Variable.swift
//  Shablonator
//
//  Created by Никита Долгов on 13.10.25.
//

import Foundation
import GRDB

struct Variable: Codable, Identifiable, Hashable {
    let id: Int64
    let stepId: Int64
    var name: String                // patient_name, appointment_date, clinic_phone
    var type: VariableType          // string, date, phone, etc
    var defaultValue: String?       // Значение по умолчанию
    var optionsJson: String?        // JSON для select типа

    init(
        id: Int64 = 0,
        stepId: Int64,
        name: String,
        type: VariableType,
        defaultValue: String? = nil,
        optionsJson: String? = nil
    ) {
        self.id = id
        self.stepId = stepId
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.optionsJson = optionsJson
    }

    enum VariableType: String, CaseIterable, Codable, DatabaseValueConvertible {
        case string = "string"
        case date = "date"
        case time = "time"
        case datetime = "datetime"
        case number = "number"
        case phone = "phone"
        case email = "email"
        case select = "select"
        case boolean = "boolean"
        case amount = "amount"
        case url = "url"

        var displayName: String {
            switch self {
            case .string: return "Текст"
            case .date: return "Дата"
            case .time: return "Время"
            case .datetime: return "Дата и время"
            case .number: return "Число"
            case .phone: return "Телефон"
            case .email: return "Email"
            case .select: return "Выбор из списка"
            case .boolean: return "Да/Нет"
            case .amount: return "Сумма в рублях"
            case .url: return "Ссылка"
            }
        }

        var placeholder: String {
            switch self {
            case .string: return "Введите текст"
            case .date: return "дд.мм.гггг"
            case .time: return "чч:мм"
            case .datetime: return "дд.мм.гггг чч:мм"
            case .number: return "Введите число"
            case .phone: return "+7 (999) 999-99-99"
            case .email: return "example@email.com"
            case .select: return "Выберите вариант"
            case .boolean: return "Да/Нет"
            case .amount: return "0.00 ₽"
            case .url: return "https://example.com"
            }
        }

        var icon: String {
            switch self {
            case .string: return "textformat"
            case .date: return "calendar"
            case .time: return "clock"
            case .datetime: return "calendar.badge.clock"
            case .number: return "number"
            case .phone: return "phone"
            case .email: return "envelope"
            case .select: return "list.bullet"
            case .boolean: return "checkmark.circle"
            case .amount: return "rublesign.circle"
            case .url: return "link"
            }
        }
    }

    // Computed properties
    var options: [String] {
        guard let optionsJson = optionsJson,
              let data = optionsJson.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [String] else {
            return []
        }
        return array
    }

    var templateVariable: String {
        return "{\(name)}"
    }

    var isRequired: Bool {
        return defaultValue == nil
    }

    var displayName: String {
        return name.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - GRDB Record Conformance
extension Variable: FetchableRecord, MutablePersistableRecord {

    static let databaseTableName = "variable"

    // Связь с шагом
    static let step = belongsTo(Step.self)

    init(row: Row) {
        id = row["id"]
        stepId = row["step_id"]
        name = row["name"]
        type = VariableType(rawValue: row["type"]) ?? .string
        defaultValue = row["default_value"]
        optionsJson = row["options_json"]
    }

    func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["step_id"] = stepId
        container["name"] = name
        container["type"] = type.rawValue
        container["default_value"] = defaultValue
        container["options_json"] = optionsJson
    }
}

// MARK: - Database Queries
extension Variable {

    /// Получить переменные для конкретного шага
    static func forStep(_ stepId: Int64) -> QueryInterfaceRequest<Variable> {
        return Variable.filter(Column("step_id") == stepId)
            .order(Column("name"))
    }

    /// Получить переменные определенного типа
    static func ofType(_ type: VariableType) -> QueryInterfaceRequest<Variable> {
        return Variable.filter(Column("type") == type.rawValue)
            .order(Column("name"))
    }

    /// Получить обязательные переменные (без значения по умолчанию)
    static func required() -> QueryInterfaceRequest<Variable> {
        return Variable.filter(Column("default_value") == nil || Column("default_value") == "")
            .order(Column("name"))
    }

    /// Поиск переменной по имени
    static func named(_ name: String) -> QueryInterfaceRequest<Variable> {
        return Variable.filter(Column("name") == name)
    }
}

// MARK: - Общие переменные для стоматологической клиники
extension Variable {

    static let commonDentalVariables: [(String, VariableType, String?)] = [
        ("patient_name", .string, nil),
        ("patient_first_name", .string, nil),
        ("patient_last_name", .string, nil),
        ("patient_phone", .phone, nil),
        ("patient_email", .email, nil),
        ("appointment_date", .date, nil),
        ("appointment_time", .time, nil),
        ("doctor_name", .string, "Доктор"),
        ("clinic_name", .string, "Стоматологическая клиника"),
        ("clinic_phone", .phone, "+7 (495) 123-45-67"),
        ("clinic_address", .string, "г. Москва"),
        ("clinic_website", .url, "https://clinic.ru"),
        ("treatment_name", .string, "лечение"),
        ("treatment_cost", .amount, nil),
        ("next_visit_date", .date, nil),
        ("payment_amount", .amount, nil),
        ("discount_percent", .number, nil),
        ("insurance_accepted", .boolean, "Да"),
        ("emergency_phone", .phone, "+7 (495) 911-22-33")
    ]

    /// Создать общую переменную для стоматологии
    static func createCommonVariable(name: String, stepId: Int64) -> Variable? {
        guard let common = commonDentalVariables.first(where: { $0.0 == name }) else {
            return nil
        }

        return Variable(
            stepId: stepId,
            name: common.0,
            type: common.1,
            defaultValue: common.2
        )
    }

    /// Получить все доступные общие переменные
    static func availableCommonVariables() -> [String] {
        return commonDentalVariables.map { $0.0 }
    }
}
