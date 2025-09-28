//
//  BuilderTransitionsVC.swift
//  Shablonator
//
//  Created by Никита Долгов on 20.09.25.
//

import UIKit

final class BuilderTransitionsVC: UITableViewController {
    private let state: BuilderState
    var onNext: (() -> Void)?

    init(state: BuilderState) { self.state = state; super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Переходы"
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped)),
            UIBarButtonItem(title: "Далее", style: .done, target: self, action: #selector(nextTapped))
        ]
    }

    @objc private func nextTapped() {
        print("nextTapped called")
        print("onNext is nil: \(onNext == nil)")
        onNext?()
    }

    @objc private func addTapped() {
        let editor = TransitionEditorVC(state: state)
        editor.onSave = { [weak self] t in
            self?.state.transitions.append(t)
            self?.tableView.reloadData()
        }
        present(UINavigationController(rootViewController: editor), animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { state.transitions.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let t = state.transitions[indexPath.row]
        let c = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        c.textLabel?.text = "from \(t.fromLocalId) → to \(t.toLocalId)  \(t.label ?? "")"
        c.detailTextLabel?.text = t.conditionJson ?? "без условия"
        return c
    }
}

final class TransitionEditorVC: UITableViewController {
    private let state: BuilderState
    var onSave: ((BuilderState.TransitionDraft) -> Void)?

    private let fromField = UITextField()
    private let toField = UITextField()
    private let labelField = UITextField()
    private let keyField = UITextField()
    private let valueField = UITextField()

    init(state: BuilderState) { self.state = state; super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Переход"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Сохранить", style: .done, target: self, action: #selector(save))
        fromField.placeholder = "from localId"; fromField.keyboardType = .numberPad
        toField.placeholder = "to localId"; toField.keyboardType = .numberPad
        labelField.placeholder = "label (опц.)"
        keyField.placeholder = "key (опц.)"
        valueField.placeholder = "value"
    }

    @objc private func save() {
        guard let f = Int64(fromField.text ?? ""), let t = Int64(toField.text ?? "") else { return }
        var cond: String?
        if let key = keyField.text, !key.isEmpty, let val = valueField.text, !val.isEmpty {
            cond = #"{"if":"\#(key)==\"\#(val)\""}"#
        }
        onSave?(BuilderState.TransitionDraft(fromLocalId: f, toLocalId: t, label: labelField.text, conditionJson: cond))
        dismiss(animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 5 }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let c = UITableViewCell(style: .value1, reuseIdentifier: nil)
        let field: UITextField
        switch indexPath.row {
        case 0: c.textLabel?.text = "from"; field = fromField
        case 1: c.textLabel?.text = "to"; field = toField
        case 2: c.textLabel?.text = "label"; field = labelField
        case 3: c.textLabel?.text = "key"; field = keyField
        default: c.textLabel?.text = "value"; field = valueField
        }
        field.borderStyle = .roundedRect
        c.contentView.addSubview(field)
        field.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            field.trailingAnchor.constraint(equalTo: c.contentView.trailingAnchor, constant: -16),
            field.centerYAnchor.constraint(equalTo: c.contentView.centerYAnchor),
            field.widthAnchor.constraint(equalToConstant: 220)
        ])
        return c
    }
}

