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

    // MARK: - UI
    private let searchBar = UISearchBar()
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let overlay = UIView()
    private let addButton = UIButton(type: .custom)

    // MARK: - Data
    private let repo = TemplateRepository()
    private var allTemplates: [(TemplateRecord, Int)] = []
    private var filtered: [(TemplateRecord, Int)] = []
    private var selectedTemplateId: Int64?

    // MARK: - Callback
    var onSelectTemplate: ((TemplateRecord) -> Void)?
//    private var currentBuilder: TemplateBuilderCoordinator?

    // MARK: - Combine
    private let searchSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupSearchBar()
        setupList()
        setupOverlay()
        setupSearchPipeline()
        setupAddButton()
        loadTemplates()
    }

    // MARK: - Data
    func loadTemplates() {
        do {
            allTemplates = try repo.templatesWithStepCount(userId: 1)
            filtered = allTemplates
            reload(with: filtered)
        } catch {
            showError("Не удалось загрузить шаблоны: \(error.localizedDescription)")
        }
    }

    // MARK: - Search
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Поиск..."
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
    }

    private func setupSearchPipeline() {
        searchSubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self else { return }
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.filtered = self.allTemplates
                } else {
                    self.filtered = self.allTemplates.filter {
                        $0.0.name.localizedCaseInsensitiveContains(text) ||
                        ($0.0.description ?? "").localizedCaseInsensitiveContains(text) ||
                        "\($0.1)".contains(text)
                    }
                }
                self.reload(with: self.filtered)
            }
            .store(in: &cancellables)
    }

    // MARK: - List
    private func setupList() {
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        scrollView.keyboardDismissMode = .onDrag

        scrollView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(16)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-32)
        }
    }

    // MARK: - Overlay
    private func setupOverlay() {
        overlay.backgroundColor = .clear
        overlay.isHidden = true
        view.addSubview(overlay)
        overlay.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSearchMode))
        tap.cancelsTouchesInView = true
        overlay.addGestureRecognizer(tap)
    }

    @objc private func dismissSearchMode() {
        view.endEditing(true)
        overlay.isHidden = true
    }

    // MARK: - Add Button + Actions
    private func setupAddButton() {
        addButton.backgroundColor = .systemBlue
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = .white
        addButton.layer.cornerRadius = 28
        addButton.layer.shadowColor = UIColor.black.cgColor
        addButton.layer.shadowOpacity = 0.15
        addButton.layer.shadowRadius = 6
        addButton.layer.shadowOffset = CGSize(width: 0, height: 2)

        view.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.size.equalTo(56)
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        addButton.addAction(UIAction { [weak self] _ in
            self?.addTapped()
        }, for: .touchUpInside)
    }

    private func addTapped() {
        let sheet = UIAlertController(title: "Создать шаблон", message: nil, preferredStyle: .actionSheet)

        sheet.addAction(UIAlertAction(title: "Простой шаблон", style: .default) { [weak self] _ in
            guard let self else { return }
            let editor = TemplateEditorViewController(userId: 1)
            editor.onCreated = { [weak self] created in
                self?.loadTemplates()
                self?.selectedTemplateId = created.id
                if let rec = self?.allTemplates.first(where: { $0.0.id == created.id })?.0 {
                    self?.onSelectTemplate?(rec)
                }
            }
            self.present(editor, animated: true)
        })

        sheet.addAction(UIAlertAction(title: "Конструктор шагов", style: .default) { [weak self] _ in
            self?.startBuilder()
        })

        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(sheet, animated: true)
    }

    private func startBuilder() {
        // Используем новый объединенный билдер
        let builder = UnifiedTemplateBuilderViewController()
        builder.onSave = { [weak self] builderState in
            self?.createTemplateFromBuilderState(builderState)
        }
        
        let nav = UINavigationController(rootViewController: builder)
        nav.modalPresentationStyle = .fullScreen
        
        builder.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Отмена",
            style: .plain,
            target: self,
            action: #selector(dismissBuilder)
        )
        
        present(nav, animated: true)
    }
    
    @objc private func dismissBuilder() {
        dismiss(animated: true)
    }

    private func createTemplateFromBuilderState(_ builderState: BuilderState) {
        do {
            let templateId = try repo.createFromBuilder(builderState)
            
            dismiss(animated: true) {
                self.loadTemplates()
                self.selectedTemplateId = templateId
                
                if let template = self.allTemplates.first(where: { $0.0.id == templateId })?.0 {
                    self.onSelectTemplate?(template)
                }
            }
            
        } catch {
            showError("Не удалось создать шаблон: \(error.localizedDescription)")
        }
    }

    private func createStepsFromBuilder(templateId: Int64, steps: [BuilderElement]) throws {
        for (index, element) in steps.enumerated() {
            let stepTitle = "\(element.type.displayName) \(index + 1)"
            let stepContent = generateContentForElement(element)
            
            try repo.createStep(
                templateId: templateId,
                title: stepTitle,
                content: stepContent,
                kind: element.type.rawValue.description,
                sortHint: index * 10
            )
        }
    }

    private func generateContentForElement(_ element: BuilderElement) -> String {
        switch element.type {
        case .question:
            return "Задайте вопрос пользователю"
        case .choice:
            return "Предложите варианты выбора"
        case .textInput:
            return "Запросите ввод текста"
        case .info:
            return "Покажите информацию"
        case .condition:
            return "Проверьте условие"
        case .result:
            return "Покажите результат"
        }
    }

    // MARK: - Render
    
    
    
    private func reload(with items: [(TemplateRecord, Int)]) {
        stackView.arrangedSubviews.forEach { v in
            stackView.removeArrangedSubview(v)
            v.removeFromSuperview()
        }

        if items.isEmpty, !(searchBar.text ?? "").isEmpty {
            let label = UILabel()
            label.text = "Шаблоны не найдены"
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 16)
            stackView.addArrangedSubview(label)
            label.snp.makeConstraints { $0.height.greaterThanOrEqualTo(100) }
            return
        }

        items.forEach { (template, stepCount) in
            let isSelected = template.id == selectedTemplateId
            let card = CardFactory.templateCard(
                title: template.name,
                stepCount: stepCount,
                hasVideo: stepCount > 5,
                isSelected: isSelected,
                onTap: { [weak self] in
                    guard let self else { return }
                    self.view.endEditing(true)
                    self.overlay.isHidden = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    self.selectedTemplateId = template.id
                    self.onSelectTemplate?(template)
                    self.reload(with: self.filtered)
                    self.startScenario(template: template)
                },
                onEdit: { [weak self] in
                    guard let self else { return }
                    self.view.endEditing(true)
                    self.overlay.isHidden = true
                    // TODO: режим редактирования существующего шаблона
                    let editor = TemplateEditorViewController(userId: template.userId)
                    editor.onCreated = { [weak self] _ in self?.loadTemplates() }
                    self.present(editor, animated: true)
                }
            )
            stackView.addArrangedSubview(card)
        }
    }

    private func startScenario(template: TemplateRecord) {
        let player = StepPlayerViewController(template: template)
        player.delegate = self
        player.modalPresentationStyle = .fullScreen
        present(player, animated: true)
    }

    private func showError(_ message: String) {
        let ac = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension TemplatesViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) { overlay.isHidden = false }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) { overlay.isHidden = true }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) { searchSubject.send(searchText) }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { dismissSearchMode() }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismissSearchMode()
        searchBar.text = ""
        filtered = allTemplates
        reload(with: filtered)
    }
}

// MARK: - StepPlayerDelegate
extension TemplatesViewController: StepPlayerDelegate {
    func stepPlayerDidFinish(_ player: StepPlayerViewController, state: StepState) {
        dismiss(animated: true)
        print("Scenario finished with:", state.getAllValues())
    }
    func stepPlayerDidCancel(_ player: StepPlayerViewController) {
        dismiss(animated: true)
    }
}
