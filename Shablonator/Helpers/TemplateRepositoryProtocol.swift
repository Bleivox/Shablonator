//
//  TemplateRepositoryProtocol.swift
//  Shablonator
//
//  Created by Никита Долгов on 13.10.25.
//

import Foundation
import GRDB
import Combine

protocol TemplateRepositoryProtocol {
    // MARK: - Базовые CRUD операции
    func getAllTemplates() -> AnyPublisher<[Template], Error>
    func getTemplate(id: Int64) -> AnyPublisher<Template?, Error>
    func getTemplateWithSteps(id: Int64) -> AnyPublisher<Template?, Error>
    func createTemplate(_ template: Template) -> AnyPublisher<Template, Error>
    func updateTemplate(_ template: Template) -> AnyPublisher<Template, Error>
    func deleteTemplate(id: Int64) -> AnyPublisher<Void, Error>

    // MARK: - Поиск и фильтрация
    func searchTemplates(query: String) -> AnyPublisher<[Template], Error>
    func getActiveTemplates() -> AnyPublisher<[Template], Error>

    // MARK: - Работа с шагами
    func getStepsForTemplate(id: Int64) -> AnyPublisher<[Step], Error>
    func addStepToTemplate(step: Step) -> AnyPublisher<Step, Error>
    func updateStep(_ step: Step) -> AnyPublisher<Step, Error>
    func deleteStep(id: Int64) -> AnyPublisher<Void, Error>

    // MARK: - Реактивные запросы для SwiftUI/Combine
    func observeAllTemplates() -> DatabasePublishers.Value<[Template]>
    func observeTemplate(id: Int64) -> DatabasePublishers.Value<Template?>
    func observeTemplateWithSteps(id: Int64) -> DatabasePublishers.Value<Template?>
}
