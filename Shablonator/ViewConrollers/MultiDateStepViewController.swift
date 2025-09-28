//
//  MultiDateStepViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 19.09.25.
//

import UIKit
import SnapKit

final class MultiDateStepViewController: UIViewController {
    private let step: StepRecord
    private let repository: StepRepository
    private let onComplete: ([StepChoice]) -> Void
    
    // UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let picker = UIDatePicker()
    private let addButton = UIButton(type: .system)
    private let table = UITableView(frame: .zero, style: .insetGrouped)
    private let doneButton = UIButton(type: .system)
    
    // State
    private var selected: [Date] = []
    private var minuteInterval = 15
    private var minCount = 1
    private var maxCount = 6
    private let cal = Calendar.current
    
    private var tableHeightConstraint: Constraint?
    
    init(step: StepRecord, repository: StepRepository, onComplete: @escaping ([StepChoice]) -> Void) {
        self.step = step
        self.repository = repository
        self.onComplete = onComplete
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureOptions()
        setupUI()
        setupActions()
        syncButtons()
    }
    
    private func configureOptions() {
        if let stepId = step.id,
           let vars = try? repository.variables(for: stepId),
           let v = vars.first(where: { $0.type == "dateList" }),
           let opts = v.parseOptions() {
            if let mi = opts["minuteInterval"] as? Int { minuteInterval = mi }
            if let minC = opts["minCount"] as? Int { minCount = minC }
            if let maxC = opts["maxCount"] as? Int { maxCount = maxC }
        }
    }
    
    private func setupUI() {
        // Scroll + content
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(72) // место под кнопку
        }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        // Title
        titleLabel.text = step.title ?? "Выбор дат"
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        // Picker
        picker.preferredDatePickerStyle = .inline
        picker.datePickerMode = .dateAndTime
        picker.minuteInterval = minuteInterval
        
        // Add button
        var addCfg = UIButton.Configuration.filled()
        addCfg.title = "Добавить слот"
        addCfg.cornerStyle = .medium
        addCfg.contentInsets = .init(top: 12, leading: 16, bottom: 12, trailing: 16)
        addButton.configuration = addCfg
        
        // Table
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.isScrollEnabled = false
        
        // Done button (fixed at bottom)
        var doneCfg = UIButton.Configuration.filled()
        doneCfg.title = "Готово"
        doneCfg.cornerStyle = .large
        doneCfg.baseBackgroundColor = .systemBlue
        doneCfg.baseForegroundColor = .white
        doneCfg.contentInsets = .init(top: 14, leading: 18, bottom: 14, trailing: 18)
        doneButton.configuration = doneCfg
        
        // Layout
        contentView.addSubview(titleLabel)
        contentView.addSubview(picker)
        contentView.addSubview(addButton)
        contentView.addSubview(table)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        picker.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        addButton.snp.makeConstraints { make in
            make.top.equalTo(picker.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
        table.snp.makeConstraints { make in
                    make.top.equalTo(addButton.snp.bottom).offset(12)
                    make.leading.trailing.equalToSuperview().inset(8)
                    // 1) создаём ОДНУ высотную констрейнт c = 0 (priority 999) и сохраняем ссылку
                    tableHeightConstraint = make.height.equalTo(0).priority(999).constraint
                    make.bottom.equalToSuperview().inset(12)
                }
        
        view.addSubview(doneButton)
        doneButton.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(12)
            make.height.equalTo(54)
        }
    }
    
    private func setupActions() {
        addButton.addAction(UIAction { [weak self] _ in self?.addCurrentPicker() }, for: .touchUpInside)
        doneButton.addAction(UIAction { [weak self] _ in self?.doneTapped() }, for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(doneTapped))
    }
    
    private func syncButtons() {
        addButton.isEnabled = selected.count < maxCount
        let ok = selected.count >= minCount
        doneButton.isEnabled = ok
        navigationItem.rightBarButtonItem?.isEnabled = ok
    }
    
    private func addCurrentPicker() {
        let d = rounded(picker.date, to: minuteInterval)
        guard !selected.contains(where: { abs($0.timeIntervalSince(d)) < 1 }) else { return }
        selected.append(d)
        selected.sort()
        table.reloadData()
        // пересчитать высоту таблицы
        table.layoutIfNeeded()
        table.snp.updateConstraints { $0.height.equalTo(table.contentSize.height).priority(999) }
        syncButtons()
    }
    
    private func rounded(_ date: Date, to minutes: Int) -> Date {
        let m = cal.component(.minute, from: date)
        let rounded = (m / minutes) * minutes
        var comps = cal.dateComponents([.year,.month,.day,.hour], from: date)
        comps.minute = rounded
        comps.second = 0
        return cal.date(from: comps) ?? date
    }
    
    @objc private func doneTapped() {
        guard selected.count >= minCount else { return }
        let choice = StepChoice(key: "dates", value: selected, label: nil)
        onComplete([choice])
    }
}

// MARK: - Table
extension MultiDateStepViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { selected.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let d = selected[indexPath.row]
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "d MMMM yyyy, HH:mm"
        var conf = cell.defaultContentConfiguration()
        conf.text = df.string(from: d)
        cell.contentConfiguration = conf
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        let del = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _,_,done in
            guard let self else { return }
            self.selected.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.layoutIfNeeded()
            let h = tableView.contentSize.height
            self.tableHeightConstraint?.update(offset: max(h, 1))
            self.syncButtons()
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [del])
    }

}
