//
//  GRDBManager.swift
//  Shablonator
//
//  Created by Никита Долгов on 13.10.25.
//

import Foundation
import GRDB

final class GRDBManager {
    static let shared = GRDBManager()

    private var dbQueue: DatabaseQueue!

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            // Путь к базе данных в Documents
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let databasePath = (documentsPath as NSString).appendingPathComponent("Shablonator.sqlite")

            // ✅ ИСПРАВЛЕНО: Настройки PRAGMA ПЕРЕД созданием DatabaseQueue
            var config = Configuration()
            config.prepareDatabase { db in
                try db.execute(sql: "PRAGMA journal_mode=WAL")
                try db.execute(sql: "PRAGMA synchronous=NORMAL")
                try db.execute(sql: "PRAGMA cache_size=10000")
                try db.execute(sql: "PRAGMA temp_store=MEMORY")
                try db.execute(sql: "PRAGMA foreign_keys=ON")  // Включаем поддержку foreign keys
            }

            // Создаем DatabaseQueue с конфигурацией
            dbQueue = try DatabaseQueue(path: databasePath, configuration: config)

            print("✅ GRDB база данных открыта: \(databasePath)")

            // Запускаем миграции
            try migrator.migrate(dbQueue)

        } catch {
            fatalError("❌ Ошибка инициализации GRDB: \(error)")
        }
    }

    /// Получить DatabaseQueue для использования в Repository
    func getDatabaseQueue() -> DatabaseQueue {
        return dbQueue
    }
}

// MARK: - Database Migrations
extension GRDBManager {

    /// Система миграций для управления схемой БД
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        // ✅ Миграция v1.0 - Основные таблицы
        migrator.registerMigration("v1.0-core-tables") { db in

            // Таблица шаблонов
            try db.create(table: "template") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("description", .text)
                t.column("created_at", .datetime).notNull().defaults(to: Date())
                t.column("updated_at", .datetime).notNull().defaults(to: Date())
            }

            // Таблица шагов
            try db.create(table: "step") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("template_id", .integer).notNull()
                    .references("template", column: "id", onDelete: .cascade)
                t.column("title", .text).notNull()
                t.column("content", .text)                    // Описание шага
                t.column("message", .text)                    // SMS/Email текст
                t.column("kind", .text).notNull()             // sms, call, delay, etc
                t.column("is_start", .boolean).notNull().defaults(to: false)
                t.column("is_terminal", .boolean).notNull().defaults(to: false)
                t.column("sort_hint", .integer).notNull().defaults(to: 0)
                t.column("created_at", .datetime).notNull().defaults(to: Date())
                t.column("updated_at", .datetime).notNull().defaults(to: Date())
            }

            // Таблица переменных
            try db.create(table: "variable") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("step_id", .integer).notNull()
                    .references("step", column: "id", onDelete: .cascade)
                t.column("name", .text).notNull()             // patient_name, appointment_date
                t.column("type", .text).notNull()             // string, date, phone, etc
                t.column("default_value", .text)              // Значение по умолчанию
                t.column("options_json", .text)               // JSON для select типа
                t.uniqueKey(["step_id", "name"])              // Уникальная переменная в шаге
            }

            // Таблица переходов (workflow)
            try db.create(table: "transition") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("from_step_id", .integer).notNull()
                    .references("step", column: "id", onDelete: .cascade)
                t.column("to_step_id", .integer).notNull()
                    .references("step", column: "id", onDelete: .cascade)
                t.column("label", .text)                      // "Да", "Нет", "Следующий"
                t.column("condition_json", .text)             // JSON условия
            }

            // Таблица пациентов
            try db.create(table: "patient") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("first_name", .text).notNull()
                t.column("last_name", .text).notNull()
                t.column("phone", .text)
                t.column("email", .text)
                t.column("date_of_birth", .date)
                t.column("created_at", .datetime).notNull().defaults(to: Date())
                t.column("updated_at", .datetime).notNull().defaults(to: Date())
            }

            // Индексы для оптимизации запросов
            try db.create(index: "idx_step_template_id", on: "step", columns: ["template_id"])
            try db.create(index: "idx_step_kind", on: "step", columns: ["kind"])
            try db.create(index: "idx_variable_step_id", on: "variable", columns: ["step_id"])
            try db.create(index: "idx_transition_from_step", on: "transition", columns: ["from_step_id"])

            print("✅ Основные таблицы созданы")
        }

        // ✅ Миграция v1.1 - Тестовые данные для стоматологии
        migrator.registerMigration("v1.1-seed-data") { db in

            // Тестовые шаблоны
            try db.execute(sql: """
                INSERT INTO template (id, name, description) VALUES 
                (1, 'Напоминание о приеме', 'Стандартная последовательность напоминаний пациенту о предстоящем приеме'),
                (2, 'После имплантации', 'Контроль состояния пациента после установки имплантата'),
                (3, 'Профилактический осмотр', 'Приглашение на плановый профилактический осмотр');
            """)

            // Тестовые шаги для шаблона "Напоминание о приеме"
            try db.execute(sql: """
                INSERT INTO step (id, template_id, title, content, message, kind, is_start, is_terminal, sort_hint) VALUES 
                (1, 1, 'SMS за 3 дня', 'Отправить SMS напоминание за 3 дня до приема', 'Здравствуйте, {patient_name}! Напоминаем о записи {appointment_date} в {appointment_time}. Клиника: {clinic_phone}', 'sms', 1, 0, 1),
                (2, 1, 'Звонок за день', 'Телефонный звонок за день до приема для подтверждения', NULL, 'call', 0, 0, 2),
                (3, 1, 'SMS в день приема', 'Напоминание утром в день приема', 'Добрый день, {patient_name}! Сегодня ваш прием в {appointment_time}. Ждем вас!', 'sms', 0, 1, 3);
            """)

            // Тестовые шаги для шаблона "После имплантации"
            try db.execute(sql: """
                INSERT INTO step (id, template_id, title, content, message, kind, is_start, is_terminal, sort_hint) VALUES 
                (4, 2, 'Звонок через 2 часа', 'Проверить самочувствие пациента через 2 часа после операции', NULL, 'call', 1, 0, 1),
                (5, 2, 'SMS с инструкциями', 'Отправить SMS с рекомендациями по уходу', 'Уважаемый(ая) {patient_name}! Рекомендации после имплантации: избегайте твердой пищи, полощите рот каждые 2 часа. При вопросах: {clinic_phone}', 'sms', 0, 0, 2),
                (6, 2, 'Контроль через неделю', 'Звонок для назначения контрольного осмотра', NULL, 'followup', 0, 1, 3);
            """)

            // Переменные для шагов
            try db.execute(sql: """
                INSERT INTO variable (step_id, name, type, default_value) VALUES 
                (1, 'patient_name', 'string', NULL),
                (1, 'appointment_date', 'date', NULL),
                (1, 'appointment_time', 'time', NULL),
                (1, 'clinic_phone', 'phone', '+7 (495) 123-45-67'),
                (3, 'patient_name', 'string', NULL),
                (3, 'appointment_time', 'time', NULL),
                (5, 'patient_name', 'string', NULL),
                (5, 'clinic_phone', 'phone', '+7 (495) 123-45-67');
            """)

            // Переходы между шагами
            try db.execute(sql: """
                INSERT INTO transition (from_step_id, to_step_id, label) VALUES 
                (1, 2, 'Следующий шаг'),
                (2, 3, 'Подтверждено'),
                (4, 5, 'Самочувствие в норме'),
                (5, 6, 'Через неделю');
            """)

            // Тестовые пациенты
            try db.execute(sql: """
                INSERT INTO patient (id, first_name, last_name, phone, email) VALUES 
                (1, 'Анна', 'Иванова', '+7 (916) 123-45-67', 'anna.ivanova@email.com'),
                (2, 'Петр', 'Петров', '+7 (916) 765-43-21', 'petr.petrov@email.com');
            """)

            print("✅ Тестовые данные для стоматологии добавлены")
        }

        return migrator
    }
}
