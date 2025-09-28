//
//  ChoiceStepViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 18.09.25.
//

import UIKit
import SnapKit

final class ChoiceStepViewController: UIViewController {
    
    private let step: StepRecord
    private let repository: StepRepository
    private let onChoice: (StepChoice) -> Void
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let choicesStack = UIStackView()
    
    init(step: StepRecord, repository: StepRepository, onChoice: @escaping (StepChoice) -> Void) {
        self.step = step
        self.repository = repository
        self.onChoice = onChoice
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadChoices()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        // Title
        titleLabel.text = step.title
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        // Message
        messageLabel.text = step.message ?? "Выберите один из вариантов:"
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        
        // Choices stack
        choicesStack.axis = .vertical
        choicesStack.spacing = 12
        choicesStack.distribution = .fill
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(messageLabel)
        contentView.addSubview(choicesStack)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        choicesStack.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.lessThanOrEqualToSuperview().inset(32)
        }
    }
    
    private func loadChoices() {
        let choices = getChoicesForStep()
        
        for choice in choices {
            let button = createChoiceButton(choice: choice)
            choicesStack.addArrangedSubview(button)
        }
    }
    
    private func getChoicesForStep() -> [(key: String, value: Any, label: String)] {
        if step.title.lowercased().contains("подпись") {
            return [
                (key: "signature", value: "doctor", label: "Евгений"),
                (key: "signature", value: "doctorina", label: "Анастасия")
            ]
        } else {
            return [
                (key: "choice", value: "option1", label: "Вариант 1"),
                (key: "choice", value: "option2", label: "Вариант 2"),
                (key: "choice", value: "option3", label: "Вариант 3")
            ]
        }
    }
    
    private func createChoiceButton(choice: (key: String, value: Any, label: String)) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(choice.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = .tertiarySystemBackground
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        
        button.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(44)
        }
        
        button.addAction(UIAction { [weak self] _ in
            let stepChoice = StepChoice(key: choice.key, value: choice.value, label: choice.label)
            self?.onChoice(stepChoice)
        }, for: .touchUpInside)
        
        return button
    }
}
