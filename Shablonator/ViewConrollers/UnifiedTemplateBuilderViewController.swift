//
//  UnifiedTemplateBuilderViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 29.09.25.
//

import UIKit
import SnapKit

final class UnifiedTemplateBuilderViewController: UIViewController {
    
    // MARK: - UI Components
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let segmentedControl = UISegmentedControl(items: ["Основное", "Шаги", "Переходы"])
    private let containerView = UIView()
    private let saveButton = UIButton(type: .system)
    
    // MARK: - State
    private var builderState = BuilderState()
    private var currentChildController: UIViewController?
    
    // MARK: - Callbacks
    var onSave: ((BuilderState) -> Void)?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        showSection(0)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = DesignSystem.backgroundColor
        
        setupHeader()
        setupContainer()
        setupSaveButton()
        layoutComponents()
    }
    
    private func setupHeader() {
        headerView.backgroundColor = DesignSystem.primaryColor.withAlphaComponent(0.1)
        
        titleLabel.text = "Конструктор шаблонов"
        titleLabel.font = DesignSystem.titleFont
        titleLabel.textAlignment = .center
        
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }
    
    private func setupContainer() {
        containerView.backgroundColor = .clear
    }
    
    private func setupSaveButton() {
        saveButton.applyPrimaryStyle()
        saveButton.setTitle("Сохранить шаблон", for: .normal)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }
    
    private func layoutComponents() {
        view.addSubview(headerView)
        view.addSubview(containerView)
        view.addSubview(saveButton)
        
        headerView.addSubview(titleLabel)
        headerView.addSubview(segmentedControl)
        
        headerView.applyHeaderLayout()
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(DesignSystem.mediumPadding)
            make.leading.trailing.equalToSuperview().inset(DesignSystem.mediumPadding)
        }
        
        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(DesignSystem.mediumPadding)
            make.leading.trailing.equalToSuperview().inset(DesignSystem.mediumPadding)
            make.bottom.equalToSuperview().inset(DesignSystem.smallPadding)
        }
        
        containerView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(saveButton.snp.top).offset(-DesignSystem.mediumPadding)
        }
        
        saveButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(DesignSystem.mediumPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(DesignSystem.mediumPadding)
        }
    }
    
    // MARK: - Actions
    @objc private func segmentChanged() {
        showSection(segmentedControl.selectedSegmentIndex)
    }
    
    @objc private func saveTapped() {
        guard validateState() else { return }
        onSave?(builderState)
    }
    
    // MARK: - Section Management
    private func showSection(_ index: Int) {
        let viewController: UIViewController
        
        switch index {
        case 0:
            viewController = createMainSection()
        case 1:
            viewController = createStepsSection()
        case 2:
            viewController = createTransitionsSection()
        default:
            viewController = createMainSection()
        }
        
        setChildViewController(viewController)
    }
    
    private func setChildViewController(_ viewController: UIViewController) {
        // Удаляем старый контроллер
        if let current = currentChildController {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }
        
        // Добавляем новый контроллер
        addChild(viewController)
        containerView.addSubview(viewController.view)
        viewController.view.pinToSuperview()
        viewController.didMove(toParent: self)
        
        currentChildController = viewController
    }
    
    // MARK: - Section Creation
    private func createMainSection() -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        
        let stackView = UIStackView()
        stackView.applyVerticalStyle(spacing: DesignSystem.mediumPadding)
        
        // Поле названия
        let nameField = createFormField(title: "Название шаблона", placeholder: "Введите название")
        nameField.text = builderState.name
        nameField.addTarget(self, action: #selector(nameChanged(_:)), for: .editingChanged)
        
        // Поле описания
        let descriptionView = createTextView(title: "Описание", placeholder: "Введите описание")
        descriptionView.text = builderState.description
        
        let nameContainer = UIView()
        nameContainer.addSubview(nameField)
        nameField.pinToSuperview()
        
        let descContainer = UIView()
        descContainer.addSubview(descriptionView)
        descriptionView.pinToSuperview()
        
        stackView.addArrangedSubview(nameContainer)
        stackView.addArrangedSubview(descContainer)
        
        controller.view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(DesignSystem.mediumPadding)
        }
        
        return controller
    }
    
    private func createStepsSection() -> UIViewController {
        return VisualStepsBuilderViewController(state: builderState) { [weak self] updatedState in
            self?.builderState = updatedState
        }
    }
    
    private func createTransitionsSection() -> UIViewController {
        return TransitionsBuilderViewController(state: builderState) { [weak self] updatedState in
            self?.builderState = updatedState
        }
    }
    
    // MARK: - Form Helpers
    private func createFormField(title: String, placeholder: String) -> UITextField {
        let textField = UITextField()
        textField.applyStandardStyle()
        textField.placeholder = placeholder
        return textField
    }
    
    private func createTextView(title: String, placeholder: String) -> UITextView {
        let textView = UITextView()
        textView.font = DesignSystem.bodyFont
        textView.layer.cornerRadius = DesignSystem.smallRadius
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        
        textView.snp.makeConstraints { make in
            make.height.equalTo(100)
        }
        
        return textView
    }
    
    @objc private func nameChanged(_ textField: UITextField) {
        builderState.name = textField.text ?? ""
    }
    
    // MARK: - Validation
    private func validateState() -> Bool {
        guard !builderState.name.isEmpty else {
            showAlert("Введите название шаблона")
            return false
        }
        
        guard !builderState.steps.isEmpty else {
            showAlert("Добавьте хотя бы один шаг")
            return false
        }
        
        return true
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Внимание", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

