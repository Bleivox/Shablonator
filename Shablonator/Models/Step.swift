//
//  Step.swift
//  Shablonator
//
//  Created by Никита Долгов on 13.10.25.
//

import Foundation
import GRDB

struct Step: Codable, Identifiable, Hashable {
    let id: Int64
    let templateId: Int64
    var title: String
    var content: String?        // Описание для персонала
    var message: String?        // SMS/Email текст для пациента
    var kind: StepKind         // Тип шага
    var isStart: Bool          // Стартовый шаг
    var isTerminal: Bool       // Завершающий шаг
    var sortHint: Int          // Порядок сортировки
    let createdAt: Date
    var updatedAt: Date

    // Связанные данные
    var variables: [Variable]?
    var outgoingTransitions: [Transition]?
    var incomingTransitions: [Transition]?

    init(
        id: Int64 = 0,
        templateId: Int64,
        title: String,
        content: String? = nil,
        message: String? = nil,
        kind: StepKind,
        isStart: Bool = false,
        isTerminal: Bool = false,
        sortHint: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.templateId = templateId
        self.title = title
        self.content = content
        self.message = message
        self.kind = kind
        self.isStart = isStart
        self.isTerminal = isTerminal
        self.sortHint = sortHint
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum StepKind: String, CaseIterable, Codable, DatabaseValueConvertible {
        case sms = "sms"
        case call = "call"
        case email = "email"
        case appointment = "appointment"
        case reminder = "reminder"
        case delay = "delay"
        case manual = "manual"
        case condition = "condition"
        case followup = "followup"
        case payment = "payment"

        var displayName: String {
            switch self {
            case .sms: return "SMS сообщение"
            case .call: return "Телефонный звонок"
            case .email: return "Email сообщение"
            case .appointment: return "Запись на прием"
            case .reminder: return "Напоминание"
            case .delay: return "Задержка"
            case .manual: return "Ручное действие"
            case .condition: return "Условие"
            case .followup: return "Контрольный осмотр"
            case .payment: return "Оплата"
            }
        }

        var icon: String {
            switch self {
            case .sms: return "message.fill"
            case .call: return "phone.fill"
            case .email: return "envelope.fill"
            case .appointment: return "calendar"
            case .reminder: return "bell.fill"
            case .delay: return "clock.fill"
            case .manual: return "hand.raised.fill"
            case .condition: return "arrow.triangle.branch"
            case .followup: return "stethoscope"
            case .payment: return "creditcard.fill"
            }
        }

        var color: String {
            switch self {
            case .sms: return "systemBlue"
            case .call: return "systemGreen"
            case .email: return "systemPurple"
            case .appointment: return "systemOrange"
            case .reminder: return "systemYellow"
            case .delay: return "systemGray"
            case .manual: return "systemBrown"
            case .condition: return "systemRed"
            case .followup: return "systemTeal"
            case .payment: return "systemIndigo"
            }
        }

        var requiresMessage: Bool {
            return [.sms, .email].contains(self)
        }

        var allowsDelay: Bool {
            return ![.manual, .condition].contains(self)
        }
    }

    // Computed properties
    var hasMessage: Bool {
        return message != nil && !message!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var variableNames: [String] {
        return variables?.map { $0.name } ?? []
    }

    var canHaveTransitions: Bool {
        return !isTerminal
    }

    var displayTitle: String {
        return "\(kind.displayName): \(title)"
    }
}

// MARK: - GRDB Record Conformance
extension Step: FetchableRecord, MutablePersistableRecord {

    static let databaseTableName = "step"

    // Связи с другими таблицами
    static let template = belongsTo(Template.self)
    static let variables = hasMany(Variable.self)
    static let outgoingTransitions = hasMany(Transition.self, using: ForeignKey(["from_step_id"]))
    static let incomingTransitions = hasMany(Transition.self, using: ForeignKey(["to_step_id"]))

    init(row: Row) {
        id = row["id"]
        templateId = row["template_id"]
        title = row["title"]
        content = row["content"]
        message = row["message"]
        kind = StepKind(rawValue: row["kind"]) ?? .manual
        isStart = row["is_start"]
        isTerminal = row["is_terminal"]
        sortHint = row["sort_hint"]
        createdAt = row["created_at"]
        updatedAt = row["updated_at"]
    }

    func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["template_id"] = templateId
        container["title"] = title
        container["content"] = content
        container["message"] = message
        container["kind"] = kind.rawValue
        container["is_start"] = isStart
        container["is_terminal"] = isTerminal
        container["sort_hint"] = sortHint
        container["created_at"] = createdAt
        container["updated_at"] = updatedAt
    }

    mutating func willSave(_ db: Database) throws {
        updatedAt = Date()
    }
}

// MARK: - Database Queries
extension Step {

    /// Получить шаги для конкретного шаблона
    static func forTemplate(_ templateId: Int64) -> QueryInterfaceRequest<Step> {
        return Step.filter(Column("template_id") == templateId)
            .including(all: Step.variables)
            .order(Column("sort_hint"), Column("created_at"))
    }

    /// Получить стартовые шаги
    static func startingSteps() -> QueryInterfaceRequest<Step> {
        return Step.filter(Column("is_start") == true)
            .order(Column("sort_hint"))
    }

    /// Получить финальные шаги
    static func terminalSteps() -> QueryInterfaceRequest<Step> {
        return Step.filter(Column("is_terminal") == true)
            .order(Column("sort_hint"))
    }

    /// Получить шаги определенного типа
    static func ofKind(_ kind: StepKind) -> QueryInterfaceRequest<Step> {
        return Step.filter(Column("kind") == kind.rawValue)
            .order(Column("sort_hint"))
    }

    /// Получить шаги с сообщениями (SMS/Email)
    static func withMessages() -> QueryInterfaceRequest<Step> {
        return Step.filter(Column("message") != nil && Column("message") != "")
            .order(Column("sort_hint"))
    }
}
