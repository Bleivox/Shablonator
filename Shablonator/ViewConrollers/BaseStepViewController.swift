//
//  BaseStepViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 29.09.25.
//

import UIKit
import SnapKit

protocol StepViewControllerDelegate: AnyObject {
    func stepDidComplete(_ step: StepRecord, choices: [StepChoice])
    func stepDidCancel(_ step: StepRecord)
}

class BaseStepViewController: UIViewController {
    
    // MARK: - Properties
    let step: StepRecord
    let repository: StepRepository
    weak var delegate: StepViewControllerDelegate?
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    let titleLabel = UILabel()
    let messageLabel = UILabel()
    let contentContainer = UIView()
    let buttonContainer = UIView()
    let nextButton = UIButton(type: .system)
    let backButton = UIButton(type: .system)
    
    // MARK: - Data
    var choices: [StepChoice] = []
    
    // MARK: - Init
    init(step: StepRecord, repository: StepRepository) {
        self.step = step
        self.repository = repository
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBaseUI()
        setupStepSpecificContent()
    }
    
    // MARK: - Setup Methods
    private func setupBaseUI() {
        view.backgroundColor = DesignSystem.backgroundColor
        
        // Scroll View
        view.addSubview(scrollView)
        scrollView.pinToSuperview()
        
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
            make.height.greaterThanOrEqualToSuperview().priority(.low)
        }
        
        // Title
        titleLabel.text = step.title
        titleLabel.font = DesignSystem.titleFont
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        // Message
        messageLabel.text = step.message
        messageLabel.font = DesignSystem.bodyFont
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.isHidden = step.message?.isEmpty ?? true
        
        // Content Container
        contentContainer.backgroundColor = .clear
        
        // Buttons
        setupButtons()
        
        // Layout
        layoutBaseElements()
    }
    
    private func setupButtons() {
        nextButton.applyPrimaryStyle()
        nextButton.setTitle("Далее", for: .normal)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        
        backButton.applySecondaryStyle()
        backButton.setTitle("Назад", for: .normal)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.isHidden = step.isStart
    }
    
    private func layoutBaseElements() {
        let stackView = UIStackView()
        stackView.applyVerticalStyle(spacing: DesignSystem.largePadding)
        
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(DesignSystem.mediumPadding)
        }
        
        stackView.addArrangedSubview(titleLabel)
        if !messageLabel.isHidden {
            stackView.addArrangedSubview(messageLabel)
        }
        stackView.addArrangedSubview(contentContainer)
        stackView.addArrangedSubview(buttonContainer)
        
        // Button Container Layout
        let buttonStack = UIStackView()
        buttonStack.applyHorizontalStyle(spacing: DesignSystem.mediumPadding)
        
        buttonContainer.addSubview(buttonStack)
        buttonStack.pinToSuperview()
        
        if !backButton.isHidden {
            buttonStack.addArrangedSubview(backButton)
        }
        buttonStack.addArrangedSubview(nextButton)
    }
    
    // MARK: - Abstract Methods
    func setupStepSpecificContent() {
        // Override in subclasses
    }
    
    func validateStep() -> Bool {
        // Override in subclasses
        return true
    }
    
    func collectChoices() -> [StepChoice] {
        // Override in subclasses
        return []
    }
    
    // MARK: - Actions
    @objc private func nextTapped() {
        guard validateStep() else { return }
        
        let stepChoices = collectChoices()
        delegate?.stepDidComplete(step, choices: stepChoices)
    }
    
    @objc private func backTapped() {
        delegate?.stepDidCancel(step)
    }
    
    // MARK: - Helpers
    func showValidationError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func enableNextButton(_ enabled: Bool) {
        nextButton.isEnabled = enabled
        nextButton.alpha = enabled ? 1.0 : 0.5
    }
}

