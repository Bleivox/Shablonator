//
//  UniversalStepViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 29.09.25.
//

import UIKit
import SnapKit

final class UniversalStepViewController: BaseStepViewController {
    
    // MARK: - UI Components
    private var formFields: [UIView] = []
    private var choiceButtons: [UIButton] = []
    private var variables: [VariableRecord] = []
    
    // MARK: - Lifecycle
    override func setupStepSpecificContent() {
        super.setupStepSpecificContent()
        
        loadVariables()
        setupContentBasedOnStepType()
    }
    
    // MARK: - Setup Methods
    private func loadVariables() {
        guard let stepId = step.id else { return }
        
        do {
            variables = try repository.variables(for: stepId)
        } catch {
            print("Error loading variables: \(error)")
        }
    }
    
    private func setupContentBasedOnStepType() {
        switch step.kind?.lowercased() {
        case "question":
            setupQuestionContent()
        case "choice":
            setupChoiceContent()
        case "form":
            setupFormContent()
        case "branch":
            setupBranchContent()
        case "info":
            setupInfoContent()
        default:
            setupInfoContent()
        }
    }
    
    // MARK: - Question Step
    private func setupQuestionContent() {
        let questionLabel = UILabel()
        questionLabel.text = step.content
        questionLabel.font = DesignSystem.bodyFont
        questionLabel.numberOfLines = 0
        questionLabel.textAlignment = .center
        
        contentContainer.addSubview(questionLabel)
        questionLabel.centerInSuperview()
    }
    
    // MARK: - Choice Step
    private func setupChoiceContent() {
        let stackView = UIStackView()
        stackView.applyVerticalStyle(spacing: DesignSystem.mediumPadding)
        
        // Создаем кнопки для каждого варианта
        let choices = parseChoicesFromContent()
        
        for (index, choice) in choices.enumerated() {
            let button = UIButton(type: .system)
            button.applySecondaryStyle()
            button.setTitle(choice, for: .normal)
            button.tag = index
            button.addTarget(self, action: #selector(choiceButtonTapped(_:)), for: .touchUpInside)
            
            stackView.addArrangedSubview(button)
            choiceButtons.append(button)
        }
        
        contentContainer.addSubview(stackView)
        stackView.pinToSuperview()
        
        enableNextButton(false)
    }
    
    @objc private func choiceButtonTapped(_ sender: UIButton) {
        // Сброс состояния всех кнопок
        choiceButtons.forEach { button in
            button.applySecondaryStyle()
        }
        
        // Выделение выбранной кнопки
        sender.applyPrimaryStyle()
        
        // Сохранение выбора
        let choices = parseChoicesFromContent()
        if sender.tag < choices.count {
            self.choices = [StepChoice(
                key: "choice",
                value: choices[sender.tag],
                label: choices[sender.tag]  // добавляем label
            )]
            enableNextButton(true)
        }
    }
    
    // MARK: - Form Step
    private func setupFormContent() {
        let stackView = UIStackView()
        stackView.applyVerticalStyle(spacing: DesignSystem.mediumPadding)
        
        for variable in variables {
            let fieldView = createFormField(for: variable)
            stackView.addArrangedSubview(fieldView)
            formFields.append(fieldView)
        }
        
        contentContainer.addSubview(stackView)
        stackView.pinToSuperview()
    }
    
    private func createFormField(for variable: VariableRecord) -> UIView {
        let container = UIView()
        
        let label = UILabel()
        label.text = variable.name
        label.font = DesignSystem.captionFont.with(weight: .medium)
        
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        
        let inputView: UIView
        
        switch variable.type.lowercased() {
        case "text", "string":
            let textField = UITextField()
            textField.applyStandardStyle()
            textField.placeholder = variable.name
            textField.text = variable.defaultValue
            inputView = textField
            
        case "int", "number":
            let textField = UITextField()
            textField.applyStandardStyle()
            textField.placeholder = variable.name
            textField.text = variable.defaultValue
            textField.keyboardType = .numberPad
            inputView = textField
            
        case "date":
            let datePicker = UIDatePicker()
            datePicker.datePickerMode = .date
            datePicker.preferredDatePickerStyle = .compact
            inputView = datePicker
            
        default:
            let textField = UITextField()
            textField.applyStandardStyle()
            textField.placeholder = variable.name
            inputView = textField
        }
        
        container.addSubview(inputView)
        inputView.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        return container
    }
    
    // MARK: - Branch Step
    private func setupBranchContent() {
        // Branch работает как Choice, но с логическими условиями
        setupChoiceContent()
    }
    
    // MARK: - Info Step
    private func setupInfoContent() {
        let contentLabel = UILabel()
        contentLabel.text = step.content ?? "Информационный шаг"
        contentLabel.font = DesignSystem.bodyFont
        contentLabel.numberOfLines = 0
        contentLabel.textAlignment = .center
        
        contentContainer.addSubview(contentLabel)
        contentLabel.centerInSuperview()
    }
    
    // MARK: - Validation & Data Collection
    override func validateStep() -> Bool {
        switch step.kind?.lowercased() {
        case "choice", "branch":
            return !choices.isEmpty
        case "form":
            return validateFormFields()
        default:
            return true
        }
    }
    
    private func validateFormFields() -> Bool {
        for (index, field) in formFields.enumerated() {
            if let textField = findTextField(in: field),
               textField.text?.isEmpty == true {
                let variable = variables[index]
                showValidationError("Поле '\(variable.name)' не может быть пустым")
                return false
            }
        }
        return true
    }
    
    override func collectChoices() -> [StepChoice] {
        switch step.kind?.lowercased() {
        case "choice", "branch":
            return choices
        case "form":
            return collectFormChoices()
        default:
            return []
        }
    }
    
    private func collectFormChoices() -> [StepChoice] {
        var choices: [StepChoice] = []
        
        for (index, field) in formFields.enumerated() {
            let variable = variables[index]
            
            if let textField = findTextField(in: field) {
                let value = textField.text ?? ""
                choices.append(StepChoice(key: variable.name, value: value, label: variable.name))
            } else if let datePicker = findDatePicker(in: field) {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let value = formatter.string(from: datePicker.date)
                choices.append(StepChoice(key: variable.name, value: value, label: variable.name))
            }
        }
        
        return choices
    }
    
    // MARK: - Helpers
    private func parseChoicesFromContent() -> [String] {
        guard let content = step.content else { return ["Да", "Нет"] }
        
        // Простой парсинг выборов из контента
        let lines = content.components(separatedBy: .newlines)
        let choices = lines.filter { !$0.isEmpty }
        
        return choices.isEmpty ? ["Да", "Нет"] : choices
    }
    
    private func findTextField(in view: UIView) -> UITextField? {
        if let textField = view as? UITextField {
            return textField
        }
        
        for subview in view.subviews {
            if let textField = findTextField(in: subview) {
                return textField
            }
        }
        
        return nil
    }
    
    private func findDatePicker(in view: UIView) -> UIDatePicker? {
        if let datePicker = view as? UIDatePicker {
            return datePicker
        }
        
        for subview in view.subviews {
            if let datePicker = findDatePicker(in: subview) {
                return datePicker
            }
        }
        
        return nil
    }
}

