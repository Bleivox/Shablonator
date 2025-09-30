//
//  TransitionsBuilderViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 29.09.25.
//

import UIKit
import SnapKit

class TransitionsBuilderViewController: UIViewController {
    
    // MARK: - Properties
    private var builderState: BuilderState
    private let onStateChange: (BuilderState) -> Void
    
    // MARK: - UI Components
    private let tableView = UITableView()
    private let addButton = UIButton(type: .system)
    private let instructionLabel = UILabel()
    
    // MARK: - Init
    init(state: BuilderState, onStateChange: @escaping (BuilderState) -> Void) {
        self.builderState = state
        self.onStateChange = onStateChange
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = DesignSystem.backgroundColor
        
        // Инструкция
        instructionLabel.text = "Переходы определяют порядок шагов в шаблоне.\nДля создания переходов нужно сначала добавить шаги."
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        instructionLabel.textColor = .secondaryLabel
        instructionLabel.font = .systemFont(ofSize: 14)
        
        // Table View
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TransitionTableViewCell.self, forCellReuseIdentifier: "TransitionCell")
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        
        // Add Button
        addButton.setTitle("+ Добавить переход", for: .normal)
        addButton.applySecondaryStyle()
        addButton.addTarget(self, action: #selector(addTransitionTapped), for: .touchUpInside)
        
        // Layout
        view.addSubview(instructionLabel)
        view.addSubview(tableView)
        view.addSubview(addButton)
        
        instructionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(DesignSystem.mediumPadding)
            make.leading.trailing.equalToSuperview().inset(DesignSystem.mediumPadding)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(instructionLabel.snp.bottom).offset(DesignSystem.largePadding)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(addButton.snp.top).offset(-DesignSystem.mediumPadding)
        }
        
        addButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(DesignSystem.mediumPadding)
            make.bottom.equalToSuperview().inset(DesignSystem.mediumPadding)
        }
        
        updateUI()
    }
    
    // MARK: - Actions
    @objc private func addTransitionTapped() {
        // Проверяем что есть хотя бы 2 шага для создания перехода
        guard builderState.steps.count >= 2 else {
            showAlert("Для создания перехода нужно минимум 2 шага")
            return
        }
        
        showTransitionCreationAlert()
    }
    
    private func showTransitionCreationAlert() {
        let alert = UIAlertController(title: "Новый переход", message: "Выберите шаги для перехода", preferredStyle: .alert)
        
        // Создаем пикеры для выбора шагов
        let fromSteps = builderState.steps.map { "\($0.title) (ID: \($0.localId))" }
        let toSteps = builderState.steps.map { "\($0.title) (ID: \($0.localId))" }
        
        var selectedFromIndex = 0
        var selectedToIndex = 1
        
        // Простое решение - используем текстовые поля с подсказкой
        alert.addTextField { textField in
            textField.placeholder = "Откуда (название шага)"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Куда (название шага)"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Название перехода (опционально)"
        }
        
        alert.addAction(UIAlertAction(title: "Создать", style: .default) { [weak self] _ in
            guard let self = self,
                  let fromText = alert.textFields?[0].text, !fromText.isEmpty,
                  let toText = alert.textFields?[1].text, !toText.isEmpty else {
                return
            }
            
            let label = alert.textFields?[2].text ?? "Переход"
            self.createTransition(fromText: fromText, toText: toText, label: label)
        })
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    private func createTransition(fromText: String, toText: String, label: String) {
        // Ищем шаги по названию
        guard let fromStep = builderState.steps.first(where: { $0.title.lowercased().contains(fromText.lowercased()) }),
              let toStep = builderState.steps.first(where: { $0.title.lowercased().contains(toText.lowercased()) }) else {
            showAlert("Не найдены шаги с указанными названиями")
            return
        }
        
        // Проверяем что переход не существует
        let existingTransition = builderState.transitions.first {
            $0.fromLocalId == fromStep.localId && $0.toLocalId == toStep.localId
        }
        
        if existingTransition != nil {
            showAlert("Переход между этими шагами уже существует")
            return
        }
        
        // Создаем переход
        let newTransition = BuilderState.TransitionDraft(
            fromLocalId: fromStep.localId,
            toLocalId: toStep.localId,
            label: label,
            conditionJson: nil
        )
        
        builderState.transitions.append(newTransition)
        onStateChange(builderState)
        
        tableView.insertRows(at: [IndexPath(row: builderState.transitions.count - 1, section: 0)], with: .automatic)
        updateUI()
    }
    
    private func updateUI() {
        instructionLabel.isHidden = !builderState.transitions.isEmpty
        
        if builderState.steps.isEmpty {
            instructionLabel.text = "Сначала добавьте шаги во вкладке 'Шаги'"
            addButton.isEnabled = false
            addButton.alpha = 0.5
        } else if builderState.steps.count < 2 {
            instructionLabel.text = "Для создания переходов нужно минимум 2 шага"
            addButton.isEnabled = false
            addButton.alpha = 0.5
        } else {
            instructionLabel.text = "Переходы определяют порядок выполнения шагов"
            addButton.isEnabled = true
            addButton.alpha = 1.0
        }
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Внимание", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Helper Methods
    private func stepTitle(for localId: Int64) -> String {
        return builderState.steps.first { $0.localId == localId }?.title ?? "Неизвестный шаг"
    }
}

// MARK: - UITableViewDataSource & Delegate
extension TransitionsBuilderViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return builderState.transitions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransitionCell", for: indexPath) as! TransitionTableViewCell
        cell.configure(with: builderState.transitions[indexPath.row], builderState: builderState)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            builderState.transitions.remove(at: indexPath.row)
            onStateChange(builderState)
            tableView.deleteRows(at: [indexPath], with: .fade)
            updateUI()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - TransitionTableViewCell
class TransitionTableViewCell: UITableViewCell {
    
    private let containerView = UIView()
    private let fromLabel = UILabel()
    private let arrowLabel = UILabel()
    private let toLabel = UILabel()
    private let transitionLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Container
        containerView.backgroundColor = DesignSystem.cardColor
        containerView.layer.cornerRadius = DesignSystem.smallRadius
        containerView.layer.borderColor = UIColor.systemGray4.cgColor
        containerView.layer.borderWidth = 1
        
        // Labels
        fromLabel.font = .systemFont(ofSize: 14, weight: .medium)
        fromLabel.textColor = .systemBlue
        
        arrowLabel.text = "→"
        arrowLabel.font = .systemFont(ofSize: 18)
        arrowLabel.textAlignment = .center
        arrowLabel.textColor = .systemGray
        
        toLabel.font = .systemFont(ofSize: 14, weight: .medium)
        toLabel.textColor = .systemGreen
        
        transitionLabel.font = .systemFont(ofSize: 12)
        transitionLabel.textColor = .secondaryLabel
        transitionLabel.textAlignment = .center
        
        // Layout
        contentView.addSubview(containerView)
        containerView.addSubview(fromLabel)
        containerView.addSubview(arrowLabel)
        containerView.addSubview(toLabel)
        containerView.addSubview(transitionLabel)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
        }
        
        fromLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(8)
            make.width.equalTo(80)
        }
        
        arrowLabel.snp.makeConstraints { make in
            make.leading.equalTo(fromLabel.snp.trailing).offset(8)
            make.centerY.equalTo(fromLabel)
            make.width.equalTo(20)
        }
        
        toLabel.snp.makeConstraints { make in
            make.leading.equalTo(arrowLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalTo(fromLabel)
        }
        
        transitionLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.equalTo(fromLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().inset(8)
        }
    }
    
    func configure(with transition: BuilderState.TransitionDraft, builderState: BuilderState) {
        let fromStep = builderState.steps.first { $0.localId == transition.fromLocalId }
        let toStep = builderState.steps.first { $0.localId == transition.toLocalId }
        
        fromLabel.text = fromStep?.title ?? "ID: \(transition.fromLocalId)"
        toLabel.text = toStep?.title ?? "ID: \(transition.toLocalId)"
        transitionLabel.text = transition.label ?? "Переход"
    }
}

