//
//  QuestionStepViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 18.09.25.
//

import UIKit
import SnapKit

final class QuestionStepViewController: UIViewController {
    
    private let step: StepRecord
    private let repository: StepRepository
    private let onChoice: (StepChoice) -> Void
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let optionsStack = UIStackView()
    
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
        loadOptions()
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
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        // Message
        messageLabel.text = step.message
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        
        // Options stack
        optionsStack.axis = .vertical
        optionsStack.spacing = 12
        optionsStack.distribution = .fill
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(messageLabel)
        contentView.addSubview(optionsStack)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        optionsStack.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.lessThanOrEqualToSuperview().inset(32)
        }
    }
    
    private func loadOptions() {
        // Для простоты создадим стандартные варианты
        // В реальном приложении можно загружать из базы или конфигурации
        let options = getOptionsForQuestion()
        
        for option in options {
            let button = createOptionButton(option: option)
            optionsStack.addArrangedSubview(button)
        }
    }
    
    private func getOptionsForQuestion() -> [(key: String, value: Any, label: String)] {
        // Здесь можно анализировать step.content или step.title и возвращать соответствующие варианты
        // Для примера возвращаем общие варианты
        
        if step.title.lowercased().contains("консультация") {
            return [
                (key: "consultation", value: "yes", label: "Да, нужна консультация"),
                (key: "consultation", value: "no", label: "Нет, спасибо")
            ]
        } else if step.title.lowercased().contains("ожидание") {
            return [
                (key: "waiting", value: true, label: "Да"),
                (key: "waiting", value: false, label: "Нет")
            ]
        } else {
            return [
                (key: "answer", value: "yes", label: "Да"),
                (key: "answer", value: "no", label: "Нет")
            ]
        }
    }
    
    private func createOptionButton(option: (key: String, value: Any, label: String)) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(option.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 24, bottom: 16, right: 24)
        
        button.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
        
        button.addAction(UIAction { [weak self] _ in
            let choice = StepChoice(key: option.key, value: option.value, label: option.label)
            self?.onChoice(choice)
        }, for: .touchUpInside)
        
        return button
    }
}
