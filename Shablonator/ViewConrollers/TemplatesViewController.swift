//
//  TemplatesViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 05.09.25.
//

import UIKit
import Foundation
import SnapKit

final class TemplatesViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        loadTemplates()
    }
    
    private func setupScrollView() {
        view.backgroundColor = .systemBackground
        
        // Настройка scroll view [web:323][web:320]
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        // Настройка stack view [web:323][web:320]
        stackView.axis = .vertical
        stackView.spacing = 12
        scrollView.addSubview(stackView)
        
        // Констрейнты для вертикального скролла [web:323][web:320]
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.width.equalToSuperview().inset(16) // Фиксируем ширину для вертикального скролла
        }
    }
    
    private func loadTemplates() {
        let templates = [
            (title: "Урок математики", steps: 5, hasVideo: true),
            (title: "Презентация проекта", steps: 3, hasVideo: false),
            (title: "Онлайн встреча", steps: 7, hasVideo: true),
            (title: "Тренинг по продажам", steps: 4, hasVideo: true),
            (title: "Командная встреча", steps: 2, hasVideo: false),
            (title: "Командная встреча", steps: 2, hasVideo: false)
        ]
        
        templates.forEach { template in
            let card = CardFactory.templateCard(
                title: template.title,
                stepCount: template.steps,
                hasVideo: template.hasVideo,
                onTap: { [weak self] in
                    self?.openTemplate(template.title)
                },
                onEdit: { [weak self] in
                    self?.editTemplate(template.title)
                }
            )
            stackView.addArrangedSubview(card)
        }
    }
    
    private func openTemplate(_ title: String) {
        print("Open template: \(title)")
        // Здесь будет навигация к деталям шаблона
    }
    
    private func editTemplate(_ title: String) {
        print("Edit template: \(title)")
        // Здесь будет навигация к редактированию шаблона
    }
}
