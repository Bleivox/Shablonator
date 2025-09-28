//
//  BranchStepViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 18.09.25.
//

import UIKit
import SnapKit

final class BranchStepViewController: UIViewController {
    
    private let step: StepRecord
    private let repository: StepRepository
    private let onChoice: (StepChoice) -> Void
    
    private let titleLabel = UILabel()
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
        loadBranchOptions()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        titleLabel.text = step.title
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        optionsStack.axis = .vertical
        optionsStack.spacing = 8
        optionsStack.distribution = .fillEqually
        
        view.addSubview(titleLabel)
        view.addSubview(optionsStack)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        optionsStack.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.lessThanOrEqualTo(300)
        }
    }
    
    private func loadBranchOptions() {
        let options = getBranchOptions()
        
        for option in options {
            let button = createBranchButton(option: option)
            optionsStack.addArrangedSubview(button)
        }
    }
    
    private func getBranchOptions() -> [(key: String, value: Any, label: String)] {
        if step.title.lowercased().contains("время суток") {
            return [
                (key: "timeOfDay", value: "day", label: "День"),
                (key: "timeOfDay", value: "evening", label: "Вечер")
            ]
        } else if step.title.lowercased().contains("кто записывается") {
            return [
                (key: "who", value: "self", label: "Сам пациент"),
                (key: "who", value: "other", label: "Кто-то другой")
            ]
        } else {
            return [
                (key: "branch", value: "option1", label: "Вариант 1"),
                (key: "branch", value: "option2", label: "Вариант 2")
            ]
        }
    }
    
    private func createBranchButton(option: (key: String, value: Any, label: String)) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(option.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.separator.cgColor
        
        button.addAction(UIAction { [weak self] _ in
            let choice = StepChoice(key: option.key, value: option.value, label: option.label)
            self?.onChoice(choice)
        }, for: .touchUpInside)
        
        return button
    }
}
