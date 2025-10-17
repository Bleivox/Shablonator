//
//  TemplatesViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 05.09.25.
//

import UIKit
import SnapKit
import Combine

final class TemplatesViewController: UIViewController {
    
    // MARK: – Properties
    
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let viewModel = TemplateListViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBlue
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.25
        button.layer.shadowRadius = 4
        button.addTarget(self, action: #selector(addTemplateTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: – Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bindViewModel()
        viewModel.refreshTemplates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refreshTemplates()
    }
    
    // MARK: – Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Шаблоны"
        
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        view.addSubview(addButton)
        
        stackView.axis = .vertical
        stackView.spacing = 12
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.width.equalToSuperview().inset(16)
        }
        addButton.snp.makeConstraints { make in
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.width.height.equalTo(56)
        }
    }
    
    private func bindViewModel() {
        viewModel.$templates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] templates in
                self?.updateTemplateCards(templates)
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { isLoading in
                print(isLoading ? "⏳ Loading templates..." : "✅ Templates loaded")
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
    }
    
    // MARK: – Templates Rendering
    
    private func updateTemplateCards(_ templates: [Template]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        guard !templates.isEmpty else {
            stackView.addArrangedSubview(createEmptyStateView())
            return
        }
        
        templates.forEach { template in
            let card = CardFactory.templateCard(
                title: template.name,
                stepCount: template.stepCount,
                hasVideo: template.hasWorkflow,
                onTap: { [weak self] in self?.openTemplate(template) },
                onEdit: { [weak self] in self?.editTemplate(template) }
            )
            stackView.addArrangedSubview(card)
        }
    }
    
    private func createEmptyStateView() -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 12
        
        let imageView = UIImageView(image: UIImage(systemName: "doc.text.magnifyingglass"))
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        
        let title = UILabel()
        title.text = "Нет шаблонов"
        title.font = .systemFont(ofSize: 18, weight: .medium)
        title.textColor = .systemGray2
        title.textAlignment = .center
        
        let subtitle = UILabel()
        subtitle.text = "Создайте первый шаблон для быстрого набора сообщений"
        subtitle.font = .systemFont(ofSize: 14)
        subtitle.textColor = .systemGray3
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        
        container.addSubview(imageView)
        container.addSubview(title)
        container.addSubview(subtitle)
        
        imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(40)
            make.width.height.equalTo(60)
        }
        title.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        subtitle.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(title.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(40)
        }
        
        return container
    }
    
    // MARK: – Actions
    
    @objc private func addTemplateTapped() {
        let builderVC = TemplateBuilderViewController.createNew()
        builderVC.modalPresentationStyle = .pageSheet
        present(builderVC, animated: true)
    }
    
    private func openTemplate(_ template: Template) {
        let sheet = UIAlertController(
            title: template.name,
            message: "Выберите действие:",
            preferredStyle: .actionSheet
        )
        sheet.addAction(UIAlertAction(title: "👁️ Просмотреть", style: .default) { _ in
            print("Просмотр: \(template.name)")
        })
        sheet.addAction(UIAlertAction(title: "✏️ Редактировать", style: .default) { [weak self] _ in
            self?.editTemplate(template)
        })
        sheet.addAction(UIAlertAction(title: "📤 Отправить пациенту", style: .default) { _ in
            print("Отправка по шаблону: \(template.name)")
        })
        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(sheet, animated: true)
    }
    
    private func editTemplate(_ template: Template) {
        let builderVC = TemplateBuilderViewController.edit(template)
        builderVC.modalPresentationStyle = .pageSheet
        present(builderVC, animated: true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
