//
//  BuilderState.swift
//  Shablonator
//
//  Created by Никита Долгов on 19.09.25.
//

import Foundation

final class BuilderState {
    var userId: Int64 = 1
    var name: String = ""
    var description: String? = nil

    struct StepDraft: Hashable {
        var localId: Int64
        var title: String
        var kind: String      // "question", "branch", "form", "choice", "info", "summary"
        var isStart: Bool
        var isTerminal: Bool
        var sortHint: Int     // ← исправлено на sortHint
    }
    
    struct TransitionDraft: Hashable {
        var fromLocalId: Int64
        var toLocalId: Int64
        var label: String?
        var conditionJson: String?  // ← исправлено на conditionJson
    }
    
    struct VariableDraft: Hashable {
        var stepLocalId: Int64
        var name: String
        var type: String
        var defaultValue: String?
        var optionsJson: String?    // ← исправлено на optionsJson
    }

    var steps: [StepDraft] = []
    var transitions: [TransitionDraft] = []
    var variables: [VariableDraft] = []

    private var nextLocalId: Int64 = 1
    func makeLocalId() -> Int64 { defer { nextLocalId += 1 }; return nextLocalId }
}
