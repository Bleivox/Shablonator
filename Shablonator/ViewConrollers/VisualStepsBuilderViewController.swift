//
//  VisualStepsBuilderViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 29.09.25.
//

import UIKit
import SnapKit

class VisualStepsBuilderViewController: UIViewController {
    
    // MARK: - Properties
    private var builderState: BuilderState
    private let onStateChange: (BuilderState) -> Void
    
    // MARK: - UI
    private let tableView = UITableView()
    private let addButton = UIButton(type: .system)
    
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
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(StepTableViewCell.self, forCellReuseIdentifier: "StepCell")
        tableView.backgroundColor = .clear
        
        addButton.applySecondaryStyle()
        addButton.setTitle("+ Добавить шаг", for: .normal)
        addButton.addTarget(self, action: #selector(addStepTapped), for: .touchUpInside)
        
        view.addSubview(tableView)
        view.addSubview(addButton)
        
        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(addButton.snp.top).offset(-DesignSystem.mediumPadding)
        }
        
        addButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(DesignSystem.mediumPadding)
            make.bottom.equalToSuperview().inset(DesignSystem.mediumPadding)
        }
    }
    
    @objc private func addStepTapped() {
        let alert = UIAlertController(title: "Новый шаг", message: "Введите название шага", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Название шага"
        }
        
        alert.addAction(UIAlertAction(title: "Создать", style: .default) { [weak self] _ in
            guard let title = alert.textFields?.first?.text, !title.isEmpty else { return }
            self?.createNewStep(title: title)
        })
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    private func createNewStep(title: String) {
        let newStep = BuilderState.StepDraft(
            localId: builderState.makeLocalId(), // используем метод для генерации ID
            title: title,
            kind: "info",
            isStart: builderState.steps.isEmpty,
            isTerminal: false,
            sortHint: builderState.steps.count * 10
        )
        
        builderState.steps.append(newStep)
        onStateChange(builderState)
        
        tableView.insertRows(at: [IndexPath(row: builderState.steps.count - 1, section: 0)], with: .automatic)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension VisualStepsBuilderViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return builderState.steps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StepCell", for: indexPath) as! StepTableViewCell
        cell.configure(with: builderState.steps[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            builderState.steps.remove(at: indexPath.row)
            onStateChange(builderState)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

// MARK: - StepTableViewCell
class StepTableViewCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let kindLabel = UILabel()
    private let statusLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        titleLabel.font = DesignSystem.bodyFont.with(weight: .medium)
        kindLabel.font = DesignSystem.captionFont
        kindLabel.textColor = .secondaryLabel
        statusLabel.font = DesignSystem.captionFont.with(weight: .medium)
        
        let stackView = UIStackView()
        stackView.applyVerticalStyle(spacing: 4)
        
        let topStack = UIStackView()
        topStack.applyHorizontalStyle()
        topStack.distribution = .fill
        
        topStack.addArrangedSubview(titleLabel)
        topStack.addArrangedSubview(statusLabel)
        
        stackView.addArrangedSubview(topStack)
        stackView.addArrangedSubview(kindLabel)
        
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(DesignSystem.mediumPadding)
        }
    }
    
    func configure(with step: BuilderState.StepDraft) {
        titleLabel.text = step.title
        kindLabel.text = "Тип: \(step.kind)"
        
        var statusText = ""
        if step.isStart { statusText += "СТАРТ " }
        if step.isTerminal { statusText += "ФИНИШ" }
        statusLabel.text = statusText
        statusLabel.textColor = step.isStart ? .systemGreen : (step.isTerminal ? .systemRed : .clear)
    }
}

