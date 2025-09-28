//
//  TemplateEditorViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 18.09.25.
//

import UIKit
import SnapKit

final class TemplateEditorViewController: UIViewController {

    // MARK: - UI
    private let nameField = UITextField()
    private let descField = UITextView()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let stack = UIStackView()

    // MARK: - Data
    private let repo = TemplateRepository()
    private let userId: Int64
    var onCreated: ((TemplateRecord) -> Void)?

    // MARK: - Init
    init(userId: Int64) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .formSheet
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        layout()
        configure()
    }

    private func layout() {
        stack.axis = .vertical
        stack.spacing = 12

        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        let nameTitle = UILabel()
        nameTitle.text = "Название"
        nameTitle.font = .systemFont(ofSize: 14, weight: .semibold)

        nameField.placeholder = "Например: Запись на консультацию"
        nameField.borderStyle = .roundedRect

        let descTitle = UILabel()
        descTitle.text = "Описание"
        descTitle.font = .systemFont(ofSize: 14, weight: .semibold)

        descField.layer.cornerRadius = 8
        descField.layer.borderWidth = 1
        descField.layer.borderColor = UIColor.separator.cgColor
        descField.font = .systemFont(ofSize: 16)
        descField.snp.makeConstraints { $0.height.equalTo(120) }

        let buttonsRow = UIStackView()
        buttonsRow.axis = .horizontal
        buttonsRow.spacing = 12
        buttonsRow.distribution = .fillEqually

        cancelButton.setTitle("Отмена", for: .normal)
        saveButton.setTitle("Сохранить", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)

        buttonsRow.addArrangedSubview(cancelButton)
        buttonsRow.addArrangedSubview(saveButton)

        stack.addArrangedSubview(nameTitle)
        stack.addArrangedSubview(nameField)
        stack.addArrangedSubview(descTitle)
        stack.addArrangedSubview(descField)
        stack.addArrangedSubview(buttonsRow)
    }

    private func configure() {
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let desc = descField.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else {
            let alert = UIAlertController(title: "Пустое название", message: "Введите название шаблона", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        do {
            let id = try repo.createTemplate(userId: userId, name: name, description: desc)
            let created = TemplateRecord(id: id, userId: userId, name: name, description: desc)
            onCreated?(created)
            dismiss(animated: true)
        } catch {
            let alert = UIAlertController(title: "Ошибка", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}

