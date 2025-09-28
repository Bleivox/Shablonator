//
//  BuilderVariablesVC.swift
//  Shablonator
//
//  Created by Никита Долгов on 20.09.25.
//

import UIKit

final class BuilderVariablesVC: UITableViewController {
    private let state: BuilderState
    var onFinish: (() -> Void)?

    init(state: BuilderState) { self.state = state; super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Переменные"
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped)),
            UIBarButtonItem(title: "Создать", style: .done, target: self, action: #selector(finishTapped))
        ]
    }

    @objc private func finishTapped() { onFinish?() }

    @objc private func addTapped() {
        let editor = VariableEditorVC(state: state)
        editor.onSave = { [weak self] v in
            self?.state.variables.append(v)
            self?.tableView.reloadData()
        }
        present(UINavigationController(rootViewController: editor), animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { state.variables.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let v = state.variables[indexPath.row]
        let c = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        c.textLabel?.text = "\(v.name) • \(v.type)"
        c.detailTextLabel?.text = v.optionsJson ?? v.defaultValue
        return c
    }
}

final class VariableEditorVC: UITableViewController {
    private let state: BuilderState
    var onSave: ((BuilderState.VariableDraft) -> Void)?

    private let stepField = UITextField()
    private let nameField = UITextField()
    private let typeField = UITextField()
    private let defaultField = UITextField()
    private let optionsField = UITextField()

    init(state: BuilderState) { self.state = state; super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Переменная"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Сохранить", style: .done, target: self, action: #selector(save))
        stepField.placeholder = "step localId"; stepField.keyboardType = .numberPad
        nameField.placeholder = "name (например dates)"
        typeField.placeholder = "type (например dateList)"
        defaultField.placeholder = "default_value (опц.)"
        optionsField.placeholder = #"options_json, напр. {"minuteInterval":15,"minCount":1,"maxCount":6}"#
    }

    @objc private func save() {
        guard let sid = Int64(stepField.text ?? ""),
              let name = nameField.text, !name.isEmpty,
              let type = typeField.text, !type.isEmpty else { return }
        let v = BuilderState.VariableDraft(
            stepLocalId: sid,
            name: name,
            type: type,
            defaultValue: defaultField.text?.isEmpty == true ? nil : defaultField.text,
            optionsJson: optionsField.text?.isEmpty == true ? nil : optionsField.text
        )
        onSave?(v)
        dismiss(animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 5 }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let c = UITableViewCell(style: .value1, reuseIdentifier: nil)
        let field: UITextField
        switch indexPath.row {
        case 0: c.textLabel?.text = "stepId"; field = stepField
        case 1: c.textLabel?.text = "name"; field = nameField
        case 2: c.textLabel?.text = "type"; field = typeField
        case 3: c.textLabel?.text = "default"; field = defaultField
        default: c.textLabel?.text = "options"; field = optionsField
        }
        field.borderStyle = .roundedRect
        c.contentView.addSubview(field)
        field.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            field.trailingAnchor.constraint(equalTo: c.contentView.trailingAnchor, constant: -16),
            field.centerYAnchor.constraint(equalTo: c.contentView.centerYAnchor),
            field.widthAnchor.constraint(equalToConstant: 260)
        ])
        return c
    }
}

