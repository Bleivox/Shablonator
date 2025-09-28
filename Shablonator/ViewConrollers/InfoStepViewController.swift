//
//  InfoStepViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 18.09.25.
//

import UIKit
import SnapKit

final class InfoStepViewController: UIViewController {
    
    private let step: StepRecord
    private let onContinue: () -> Void
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()
    private let messageLabel = UILabel()
    private let continueButton = UIButton(type: .system)
    
    init(step: StepRecord, onContinue: @escaping () -> Void) {
        self.step = step
        self.onContinue = onContinue
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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
        
        // Content
        contentLabel.text = step.content
        contentLabel.font = .systemFont(ofSize: 18)
        contentLabel.textColor = .label
        contentLabel.numberOfLines = 0
        contentLabel.textAlignment = .left
        
        // Message
        messageLabel.text = step.message
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        
        // Continue button
        continueButton.setTitle("Продолжить", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.backgroundColor = .systemBlue
        continueButton.layer.cornerRadius = 12
        continueButton.addAction(UIAction { [weak self] _ in
            self?.onContinue()
        }, for: .touchUpInside)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(messageLabel)
        contentView.addSubview(continueButton)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        continueButton.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(56)
            make.bottom.lessThanOrEqualToSuperview().inset(32)
        }
        
        // Hide empty labels
        if step.content?.isEmpty ?? true {
            contentLabel.isHidden = true
        }
        if step.message?.isEmpty ?? true {
            messageLabel.isHidden = true
        }
    }
}
