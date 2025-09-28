//
//  StepRepository.swift
//  Shablonator
//
//  Created by Никита Долгов on 18.09.25.
//

import Foundation
import GRDB

final class StepRepository {
    private let dbq: DatabaseQueue
    
    init(dbq: DatabaseQueue = AppDatabase.shared.dbQueue) {
        self.dbq = dbq
    }
    
    // Получить все шаги шаблона
    func steps(for templateId: Int64) throws -> [StepRecord] {
        try dbq.read { db in
            try StepRecord
                .filter(Column("template_id") == templateId)
                .order(Column("sort_hint"))
                .fetchAll(db)
        }
    }
    
    // Найти стартовый шаг
    func startStep(templateId: Int64) throws -> StepRecord? {
        try dbq.read { db in
            try StepRecord
                .filter(Column("template_id") == templateId && Column("is_start") == 1)
                .fetchOne(db)
        }
    }
    
    // Получить переходы из шага
    func transitions(fromStepId: Int64) throws -> [TransitionRecord] {
        try dbq.read { db in
            try TransitionRecord
                .filter(Column("from_step_id") == fromStepId)
                .fetchAll(db)
        }
    }
    
    // Получить шаг по ID
    func step(id: Int64) throws -> StepRecord? {
        try dbq.read { db in
            try StepRecord.fetchOne(db, id: id)
        }
    }
    
    // Получить переменные шага
    func variables(for stepId: Int64) throws -> [VariableRecord] {
        try dbq.read { db in
            try VariableRecord
                .filter(Column("step_id") == stepId)
                .fetchAll(db)
        }
    }
    
    // Найти следующий шаг на основе состояния
    func nextStep(from currentStep: StepRecord, state: StepState) throws -> StepRecord? {
        let transitions = try transitions(fromStepId: currentStep.id!)

        // Сначала проверяем условные переходы
        for t in transitions {
            let groups = t.parseConditions() // [[TransitionCondition]]
            if groups.isEmpty { continue }
            // Условие истинно, если ИСТИНА хотя бы одна группа (OR),
            // а внутри группы все условия (AND) выполняются
            let matched = groups.contains { group in
                group.allSatisfy { $0.matches(state: state) }
            }
            if matched { return try step(id: t.toStepId) }
        }

        // Затем безусловные переходы
        if let fallback = transitions.first(where: { $0.parseConditions().isEmpty }) {
            return try step(id: fallback.toStepId)
        }
        return nil
    }
}

