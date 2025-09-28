//
//  TemplateBuilderCoordinator.swift
//  Shablonator
//
//  Created by Никита Долгов on 20.09.25.
//

import UIKit

final class TemplateBuilderCoordinator {
    private let navigationController: UINavigationController
    private var builderVC: VisualTemplateBuilderViewController?
    
    var onFinish: ((Int64) -> Void)?
    var onCancel: (() -> Void)?
    
    init(nav: UINavigationController) {
        self.navigationController = nav
    }
    
    func start() {
        let builder = VisualTemplateBuilderViewController()
        builder.onSave = { [weak self] builderModel in
            self?.saveTemplate(builderModel)
        }
        
        let nav = UINavigationController(rootViewController: builder)
        nav.modalPresentationStyle = .fullScreen
        
        // Добавить кнопки навигации
        builder.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        self.builderVC = builder
        navigationController.present(nav, animated: true)
    }
    
    @objc private func cancelTapped() {
        onCancel?()
    }
    
    private func saveTemplate(_ model: TemplateBuilderModel) {
        guard !model.name.isEmpty else { return }
        
        do {
            let repo = TemplateRepository()
            let templateId = try repo.createTemplate(
                userId: 1,
                name: model.name,
                description: "Создано в конструкторе. Содержит \(model.steps.count) элементов."
            )
            
            // Создать шаги из модели
            try createStepsFromBuilder(templateId: templateId, steps: model.steps)
            
            onFinish?(templateId)
            
        } catch {
            showError("Не удалось сохранить шаблон: \(error.localizedDescription)")
        }
    }
    
    private func createStepsFromBuilder(templateId: Int64, steps: [BuilderElement]) throws {
        let repo = TemplateRepository()
        
        for (index, element) in steps.enumerated() {
            let stepTitle = "\(element.type.displayName) \(index + 1)"
            let stepContent = generateContentForElement(element)
            
            try repo.createStep(
                templateId: templateId,
                title: stepTitle,
                content: stepContent,
                kind: element.type.rawValue.description,
                sortHint: index * 10
            )
        }
    }
    
    private func generateContentForElement(_ element: BuilderElement) -> String {
        switch element.type {
        case .question:
            return "Задайте вопрос пользователю"
        case .choice:
            return "Предложите варианты выбора"
        case .textInput:
            return "Запросите ввод текста"
        case .info:
            return "Покажите информацию"
        case .condition:
            return "Проверьте условие"
        case .result:
            return "Покажите результат"
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        builderVC?.present(alert, animated: true)
    }
}
