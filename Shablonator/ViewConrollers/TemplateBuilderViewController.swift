//
//  TemplateBuilderViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 13.10.25.
//

import UIKit
import SnapKit
import Combine

class TemplateBuilderViewController: UIViewController {

    // MARK: - Properties
    private let viewModel = TemplateBuilderViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var isEditingMode = false
    private var templateToEdit: Template?

    // MARK: - UI Elements
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.keyboardDismissMode = .interactive
        return scroll
    }()

    private lazy var contentView = UIView()

    private lazy var templateNameField: UITextField = {
        let field = UITextField()
        field.placeholder = "Название шаблона (например: 'Напоминание о приеме')"
        field.borderStyle = .roundedRect
        field.font = .systemFont(ofSize: 16)
        field.delegate = self
        return field
    }()

    private lazy var templateDescriptionField: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 15)
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.backgroundColor = .systemBackground
        textView.delegate = self
        return textView
    }()

    private lazy var messageTemplateField: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.backgroundColor = .systemBackground
        textView.delegate = self
        return textView
    }()

    private lazy var variablesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .systemGroupedBackground
        collection.register(VariableTagCell.self, forCellWithReuseIdentifier: VariableTagCell.identifier)
        collection.delegate = self
        collection.dataSource = self
        collection.showsHorizontalScrollIndicator = false
        return collection
    }()

    private lazy var previewView: MessagePreviewView = {
        let view = MessagePreviewView()
        view.isHidden = true
        return view
    }()

    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Сохранить шаблон", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupConstraints()
        bindViewModel()
        setupKeyboardObservers()

        if let template = templateToEdit {
            loadTemplateForEditing(template)
        }
    }

    // MARK: - Setup Methods

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = isEditingMode ? "Редактировать шаблон" : "Новый шаблон"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Превью",
            style: .plain,
            target: self,
            action: #selector(previewTapped)
        )

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(createSectionView(title: "Основная информация", content: [templateNameField, templateDescriptionField]))
        contentView.addSubview(createSectionView(title: "Текст сообщения", content: [messageTemplateField]))
        contentView.addSubview(createSectionView(title: "Доступные переменные", content: [variablesCollectionView]))
        contentView.addSubview(previewView)
        contentView.addSubview(saveButton)

        // Placeholder для описания
        if templateDescriptionField.text.isEmpty {
            addPlaceholder(to: templateDescriptionField, text: "Описание шаблона (необязательно)")
        }

        // Placeholder для сообщения
        addPlaceholder(to: messageTemplateField, text: "Введите текст сообщения...\n\nИспользуйте переменные:\n{patient_name} - имя пациента\n{appointment_date} - дата приема\n{appointment_time} - время приема\n{clinic_phone} - телефон клиники")
    }

    private func createSectionView(title: String, content: [UIView]) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 12

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label

        containerView.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }

        var previousView: UIView = titleLabel

        for (index, view) in content.enumerated() {
            containerView.addSubview(view)

            view.snp.makeConstraints { make in
                make.top.equalTo(previousView.snp.bottom).offset(12)
                make.leading.trailing.equalToSuperview().inset(16)

                if view is UITextView {
                    make.height.equalTo(view == messageTemplateField ? 120 : 80)
                } else if view is UICollectionView {
                    make.height.equalTo(50)
                }

                if index == content.count - 1 {
                    make.bottom.equalToSuperview().inset(16)
                }
            }

            previousView = view
        }

        return containerView
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        let sections = contentView.subviews.filter { $0 != previewView && $0 != saveButton }

        for (index, section) in sections.enumerated() {
            section.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)

                if index == 0 {
                    make.top.equalToSuperview().inset(16)
                } else {
                    make.top.equalTo(sections[index - 1].snp.bottom).offset(16)
                }
            }
        }

        previewView.snp.makeConstraints { make in
            make.top.equalTo(sections.last?.snp.bottom ?? contentView.snp.top).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        saveButton.snp.makeConstraints { make in
            make.top.equalTo(previewView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().inset(24)
        }
    }

    private func bindViewModel() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.saveButton.isEnabled = !isLoading
                if isLoading {
                    self?.saveButton.setTitle("Сохранение...", for: .normal)
                } else {
                    self?.saveButton.setTitle("Сохранить шаблон", for: .normal)
                }
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.showAlert(title: "Ошибка", message: error)
            }
            .store(in: &cancellables)

        viewModel.$saveSuccess
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.dismiss(animated: true)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        if hasUnsavedChanges() {
            let alert = UIAlertController(
                title: "Несохраненные изменения",
                message: "Вы действительно хотите закрыть без сохранения?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            alert.addAction(UIAlertAction(title: "Закрыть", style: .destructive) { [weak self] _ in
                self?.dismiss(animated: true)
            })
            present(alert, animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func previewTapped() {
        updatePreview()
        previewView.isHidden = !previewView.isHidden

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func saveButtonTapped() {
        guard validateInput() else { return }

        let template = Template(
            id: templateToEdit?.id ?? 0,
            name: templateNameField.text ?? "",
            description: templateDescriptionField.text.isEmpty ? nil : templateDescriptionField.text,
            createdAt: templateToEdit?.createdAt ?? Date(),
            updatedAt: Date()
        )

        let messageText = messageTemplateField.text ?? ""

        if isEditingMode {
            viewModel.updateTemplate(template, messageText: messageText)
        } else {
            viewModel.createTemplate(template, messageText: messageText)
        }
    }

    // MARK: - Helper Methods

    private func loadTemplateForEditing(_ template: Template) {
        templateNameField.text = template.name
        templateDescriptionField.text = template.description

        // Загружаем первый SMS шаг как основное сообщение
        if let steps = template.steps,
           let smsStep = steps.first(where: { $0.kind == .sms }) {
            messageTemplateField.text = smsStep.message
        }

        removePlaceholder(from: templateDescriptionField)
        removePlaceholder(from: messageTemplateField)
    }

    private func validateInput() -> Bool {
        guard let name = templateNameField.text, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "Ошибка", message: "Введите название шаблона")
            return false
        }

        guard let message = messageTemplateField.text, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "Ошибка", message: "Введите текст сообщения")
            return false
        }

        return true
    }

    private func hasUnsavedChanges() -> Bool {
        return !(templateNameField.text?.isEmpty ?? true) ||
               !(messageTemplateField.text?.isEmpty ?? true) ||
               !(templateDescriptionField.text?.isEmpty ?? true)
    }

    private func updatePreview() {
        let sampleData: [String: String] = [
            "{patient_name}": "Иван Петров",
            "{appointment_date}": "15.10.2025",
            "{appointment_time}": "14:30",
            "{clinic_phone}": "+7 (495) 123-45-67",
            "{doctor_name}": "Доктор Смирнов",
            "{clinic_name}": "Стоматология 'Белая улыбка'"
        ]

        var previewText = messageTemplateField.text ?? ""
        for (variable, value) in sampleData {
            previewText = previewText.replacingOccurrences(of: variable, with: value)
        }

        previewView.configure(with: previewText)
    }

    private func addPlaceholder(to textView: UITextView, text: String) {
        textView.text = text
        textView.textColor = .placeholderText
    }

    private func removePlaceholder(from textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let keyboardHeight = keyboardFrame.height - view.safeAreaInsets.bottom
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.scrollIndicatorInsets.bottom = keyboardHeight
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets.bottom = 0
    }
}

// MARK: - Extensions

extension TemplateBuilderViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == templateNameField {
            templateDescriptionField.becomeFirstResponder()
        }
        return true
    }
}

extension TemplateBuilderViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        removePlaceholder(from: textView)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            if textView == templateDescriptionField {
                addPlaceholder(to: textView, text: "Описание шаблона (необязательно)")
            } else if textView == messageTemplateField {
                addPlaceholder(to: textView, text: "Введите текст сообщения...")
            }
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        if textView == messageTemplateField {
            // Обновляем превью при изменении текста
            if !previewView.isHidden {
                updatePreview()
            }
        }
    }
}

extension TemplateBuilderViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.availableVariables.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VariableTagCell.identifier, for: indexPath) as! VariableTagCell
        let variable = viewModel.availableVariables[indexPath.item]
        cell.configure(with: variable)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let variable = viewModel.availableVariables[indexPath.item]

        // Вставляем переменную в текущую позицию курсора
        guard let selectedRange = messageTemplateField.selectedTextRange else { return }

        let cursorPosition = messageTemplateField.offset(from: messageTemplateField.beginningOfDocument, to: selectedRange.start)
        let currentText = messageTemplateField.text ?? ""

        let newText = (currentText as NSString).replacingCharacters(in: NSRange(location: cursorPosition, length: 0), with: "{\(variable)}")
        messageTemplateField.text = newText

        // Перемещаем курсор после вставленной переменной
        if let newPosition = messageTemplateField.position(from: messageTemplateField.beginningOfDocument, offset: cursorPosition + variable.count + 2) {
            messageTemplateField.selectedTextRange = messageTemplateField.textRange(from: newPosition, to: newPosition)
        }

        // Обновляем превью
        if !previewView.isHidden {
            updatePreview()
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let variable = viewModel.availableVariables[indexPath.item]
        let width = variable.count * 8 + 24 // Примерная ширина
        return CGSize(width: max(width, 80), height: 32)
    }
}

// MARK: - Convenience Initializers

extension TemplateBuilderViewController {

    /// Создать новый шаблон
    static func createNew() -> UINavigationController {
        let vc = TemplateBuilderViewController()
        vc.isEditingMode = false
        return UINavigationController(rootViewController: vc)
    }

    /// Редактировать существующий шаблон
    static func edit(_ template: Template) -> UINavigationController {
        let vc = TemplateBuilderViewController()
        vc.isEditingMode = true
        vc.templateToEdit = template
        return UINavigationController(rootViewController: vc)
    }
}
