//
//  AppDatabase.swift
//  Shablonator
//
//  Created by Никита Долгов on 18.09.25.
//

import Foundation
import GRDB

final class AppDatabase {
    static let shared = try! AppDatabase()
    let dbQueue: DatabaseQueue

    private init() throws {
        let fm = FileManager.default
        let appSup = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dbURL = appSup.appendingPathComponent("templates.sqlite")

        var config = Configuration()
        config.prepareDatabase { db in
            // Важно для внешних ключей
            try db.execute(sql: "PRAGMA foreign_keys = ON;")
        }

        dbQueue = try DatabaseQueue(path: dbURL.path, configuration: config)
        try migrator.migrate(dbQueue)
    }
}

extension AppDatabase {
    var migrator: DatabaseMigrator {
        var m = DatabaseMigrator()

        // 001 — базовая схема
        m.registerMigration("001-create-schema") { db in
            try db.execute(sql: """
            PRAGMA foreign_keys = ON;

            CREATE TABLE appuser (
              id INTEGER PRIMARY KEY,
              email TEXT NOT NULL UNIQUE,
              name TEXT,
              created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
              updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE template (
              id INTEGER PRIMARY KEY,
              userid INTEGER NOT NULL,
              name TEXT NOT NULL,
              description TEXT,
              created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
              updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY (userid) REFERENCES appuser(id)
                ON UPDATE CASCADE ON DELETE CASCADE,
              UNIQUE (userid, name)
            );

            CREATE TABLE step (
              id INTEGER PRIMARY KEY,
              template_id INTEGER NOT NULL,
              title TEXT NOT NULL,
              content TEXT,
              message TEXT,
              kind TEXT,
              is_start INTEGER NOT NULL DEFAULT 0 CHECK (is_start IN (0,1)),
              is_terminal INTEGER NOT NULL DEFAULT 0 CHECK (is_terminal IN (0,1)),
              sort_hint INTEGER NOT NULL DEFAULT 0,
              created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
              updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY (template_id) REFERENCES template(id)
                ON UPDATE CASCADE ON DELETE CASCADE
            );

            CREATE TABLE variable (
              id INTEGER PRIMARY KEY,
              step_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              default_value TEXT,
              options_json TEXT,
              FOREIGN KEY (step_id) REFERENCES step(id)
                ON UPDATE CASCADE ON DELETE CASCADE
            );

            CREATE TABLE transition (
              id INTEGER PRIMARY KEY,
              from_step_id INTEGER NOT NULL,
              to_step_id INTEGER NOT NULL,
              label TEXT,
              condition_json TEXT,
              CHECK (from_step_id <> to_step_id),
              FOREIGN KEY (from_step_id) REFERENCES step(id)
                ON UPDATE CASCADE ON DELETE CASCADE,
              FOREIGN KEY (to_step_id) REFERENCES step(id)
                ON UPDATE CASCADE ON DELETE CASCADE
            );

            CREATE INDEX idx_template_user   ON template(userid);
            CREATE INDEX idx_step_template   ON step(template_id);
            CREATE INDEX idx_variable_step   ON variable(step_id);
            CREATE INDEX idx_trans_from      ON transition(from_step_id);
            CREATE INDEX idx_trans_to        ON transition(to_step_id);

            CREATE TRIGGER trg_template_updated_at
            AFTER UPDATE ON template
            BEGIN
              UPDATE template SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
            END;

            CREATE TRIGGER trg_step_updated_at
            AFTER UPDATE ON step
            BEGIN
              UPDATE step SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
            END;
            """)
        }

        // 002 — сид данных (без #if dev)
        m.registerMigration("002-seed-example") { db in
            // Пользователь по умолчанию
            try db.execute(sql: """
            INSERT INTO appuser (id, email, name)
            VALUES (1, 'user@example.com', 'Default User')
            ON CONFLICT(id) DO NOTHING;
            """)

            // Если шаблон уже есть — пропускаем
            let exists = try Bool.fetchOne(
                db,
                sql: "SELECT EXISTS(SELECT 1 FROM template WHERE userid = 1 AND name = ?)",
                arguments: ["Запись на консультацию"]
            ) ?? false
            guard !exists else { return }

            // Сам шаблон
            try db.execute(sql: """
            INSERT INTO template (id, userid, name, description)
            VALUES (1, 1, 'Запись на консультацию', 'Последовательность опроса и формирования текста');
            """)

            // Шаги
            try db.execute(sql: """
            INSERT INTO step (id, template_id, title, kind, is_start, is_terminal, sort_hint) VALUES
            (10, 1, 'Консультация?', 'question', 1, 0, 10),
            (20, 1, 'Время суток', 'branch',   0, 0, 20),
            (30, 1, 'Приветствие: день',  'info', 0, 0, 30),
            (40, 1, 'Приветствие: вечер','info', 0, 0, 40),
            (50, 1, 'Долгое ожидание?', 'question', 0, 0, 50),
            (60, 1, 'Дата/Время',   'form', 0, 0, 60),
            (70, 1, 'Кто записывается?', 'branch', 0, 0, 70),
            (80, 1, 'Подпись', 'choice', 0, 0, 80),
            (90, 1, 'Итоговый текст', 'summary', 0, 1, 90);
            """)

            // Переменные формы
            try db.execute(sql: """
            INSERT INTO variable (id, step_id, name, type, default_value, options_json) VALUES
            (601, 60, 'date', 'date', NULL, NULL),
            (602, 60, 'hour', 'int',  '15', NULL),
            (603, 60, 'minute', 'int', '00', '{"roundTo":15}'),
            (604, 60, 'dates', 'dateList', NULL, '{"minuteInterval":15,"minCount":1,"maxCount":6}');
            """)

            // Переходы
            try db.execute(sql: """
            INSERT INTO transition (id, from_step_id, to_step_id, label, condition_json) VALUES
            (1001, 10, 20, 'Далее', NULL),
            (1002, 20, 30, 'День',    '{"if":"timeOfDay==\\"day\\""}'),
            (1003, 20, 40, 'Вечер',   '{"if":"timeOfDay==\\"evening\\""}'),
            (1004, 30, 50, 'Далее', NULL),
            (1005, 40, 50, 'Далее', NULL),
            (1006, 50, 60, 'Далее', '{"if":"waiting==true || waiting==false"}'),
            (1007, 60, 70, 'Далее', NULL),
            (1008, 70, 80, 'Сам пациент',   '{"if":"who==\\"self\\""}'),
            (1009, 70, 80, 'Кто-то другой', '{"if":"who==\\"other\\""}'),
            (1010, 80, 90, 'Сформировать', NULL);
            """)
        }

        return m
    }
}
