//
//  BuilderMainVC.swift
//  Shablonator
//
//  Created by Никита Долгов on 20.09.25.
//

import UIKit
import SnapKit

final class BuilderMainVC: UIViewController {

    // MARK: - State
    private let state: BuilderState
    var onNext: (() -> Void)?
    var onCancel: (() -> Void)?

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let nameField = UITextField()
    private let descField = UITextField()

    // MARK: - Init
    init(state: BuilderState) {
        self.state = state
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Шаблон"
        view.backgroundColor = .systemBackground
        setupNav()
        setupUI()
        applyInitialValues()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameField.becomeFirstResponder()
    }

    // MARK: - Navigation
    private func setupNav() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Далее",
            style: .done,
            target: self,
            action: #selector(nextTapped)
        )
    }

    @objc private func closeTapped() {
        onCancel?()
    }

    @objc private func nextTapped() {
        print("nextTapped called")
        proceed()
    }

    // MARK: - UI Setup
    private func setupUI() {
        // Scroll container
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(16)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-32)
        }

        // Main stack
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Name field
        nameField.borderStyle = .roundedRect
        nameField.placeholder = "Название шаблона"
        nameField.autocorrectionType = .no
        nameField.autocapitalizationType = .sentences
        nameField.clearButtonMode = .whileEditing
        nameField.returnKeyType = .next
        nameField.delegate = self
        nameField.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }

        // Description field
        descField.borderStyle = .roundedRect
        descField.placeholder = "Описание (опционально)"
        descField.autocorrectionType = .no
        descField.autocapitalizationType = .sentences
        descField.clearButtonMode = .whileEditing
        descField.returnKeyType = .done
        descField.delegate = self
        descField.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }

        // Add to stack
        stack.addArrangedSubview(nameField)
        stack.addArrangedSubview(descField)
        
        // Add some spacing at bottom
        let spacer = UIView()
        spacer.snp.makeConstraints { $0.height.greaterThanOrEqualTo(20) }
        stack.addArrangedSubview(spacer)
    }

    private func applyInitialValues() {
        if !state.name.isEmpty {
            nameField.text = state.name
        }
        if let desc = state.description, !desc.isEmpty {
            descField.text = desc
        }
    }

    // MARK: - Actions
    private func proceed() {
        print("proceed called")
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            let ac = UIAlertController(title: "Укажите название", message: "Название шаблона обязательно", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }
        
        // Сохранить в state
        state.name = name
        let desc = (descField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        state.description = desc.isEmpty ? nil : desc
        
        print("Moving to next step, onNext is nil: \(onNext == nil)")
        onNext?()
    }
}

// MARK: - UITextFieldDelegate
extension BuilderMainVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameField {
            descField.becomeFirstResponder()
        } else if textField == descField {
            proceed()
        }
        return true
    }
}
