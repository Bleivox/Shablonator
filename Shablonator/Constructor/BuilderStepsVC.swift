//
//  BuilderStepsVC.swift
//  Shablonator
//
//  Created by Никита Долгов on 20.09.25.
//

import UIKit
import SnapKit

final class BuilderStepsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let state: BuilderState
    var onNext: (() -> Void)?
    private let table = UITableView(frame: .zero, style: .insetGrouped)

    init(state: BuilderState) { self.state = state; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Шаги"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped)),
            UIBarButtonItem(title: "Далее", style: .done, target: self, action: #selector(nextTapped))
        ]
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(table)
        table.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
    }

    @objc private func nextTapped() { onNext?() }

    @objc private func addTapped() {
        let editor = StepEditorVC()
        editor.onSave = { [weak self] draft in
            guard let self else { return }
            var s = draft
            s.localId = self.state.makeLocalId()
            // единственный стартовый шаг
            if s.isStart { self.state.steps = self.state.steps.map { var x = $0; x.isStart = (x.localId == s.localId); return x } }
            self.state.steps.append(s)
            self.state.steps.sort { $0.sortHint < $1.sortHint }
            self.table.reloadData()
        }
        present(UINavigationController(rootViewController: editor), animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { state.steps.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let s = state.steps[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var conf = cell.defaultContentConfiguration()
        conf.text = "\(s.sortHint). \(s.title)"
        conf.secondaryText = "\(s.kind)\(s.isStart ? " • start" : "")\(s.isTerminal ? " • terminal" : "")"
        cell.contentConfiguration = conf
        return cell
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let del = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _,_,done in
            self?.state.steps.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [del])
    }
}

final class StepEditorVC: UITableViewController {
    var onSave: ((BuilderState.StepDraft) -> Void)?
    private let titleField = UITextField()
    private let kinds = ["question","branch","form","choice","info","summary"]
    private let kindPicker = UISegmentedControl(items: ["Q","B","F","C","I","S"])
    private let startSwitch = UISwitch()
    private let terminalSwitch = UISwitch()
    private let sortField = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Шаг"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Сохранить", style: .done, target: self, action: #selector(save))
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        sortField.keyboardType = .numberPad
        kindPicker.selectedSegmentIndex = 0
    }

    @objc private func save() {
        let titleText = titleField.text?.isEmpty == false ? titleField.text! : "Без названия"
        let kind = kinds[max(kindPicker.selectedSegmentIndex,0)]
        let sortHint = Int(sortField.text ?? "") ?? 0
        onSave?(BuilderState.StepDraft(localId: -1, title: titleText, kind: kind, isStart: startSwitch.isOn, isTerminal: terminalSwitch.isOn, sortHint: sortHint))
        dismiss(animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 5 }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let c = UITableViewCell(style: .value1, reuseIdentifier: nil)
        switch indexPath.row {
        case 0: c.textLabel?.text = "Заголовок"; attach(c, titleField)
        case 1:
            c.textLabel?.text = "Тип"
            c.contentView.addSubview(kindPicker)
            kindPicker.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                kindPicker.trailingAnchor.constraint(equalTo: c.contentView.trailingAnchor, constant: -16),
                kindPicker.centerYAnchor.constraint(equalTo: c.contentView.centerYAnchor)
            ])
        case 2: c.textLabel?.text = "Стартовый"; c.accessoryView = startSwitch
        case 3: c.textLabel?.text = "Терминальный"; c.accessoryView = terminalSwitch
        case 4: c.textLabel?.text = "Порядок"; attach(c, sortField)
        default: break
        }
        return c
    }

    private func attach(_ cell: UITableViewCell, _ field: UITextField) {
        field.borderStyle = .roundedRect
        cell.contentView.addSubview(field)
        field.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            field.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            field.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            field.widthAnchor.constraint(equalToConstant: 220)
        ])
    }
}

