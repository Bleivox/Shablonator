//
//  DateTimeCalendarController.swift
//  Shablonator
//
//  Created by Никита Долгов on 19.09.25.
//

import UIKit

final class DateTimeCalendarController: UITableViewController {
    // Внешние колбэки
    var onChange: ((Date) -> Void)?
    
    // Состояние
    private var dateOn = true
    private var timeOn = false
    private var date: Date = Date()
    private var time: Date = Date() // хранит только компоненты времени
    private let cal = Calendar.current
    
    // Идентификаторы
    private enum Row { case dateHeader, datePicker, timeHeader, timePicker }
    private var rows: [Row] = [.dateHeader, .timeHeader]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(HeaderCell.self, forCellReuseIdentifier: HeaderCell.reuse) // ← регистрация
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.allowsSelection = true
        rebuildRows(animated: false)
    }
    
    private func rebuildRows(animated: Bool) {
        var newRows: [Row] = [.dateHeader]
        if dateOn { newRows.append(.datePicker) }
        newRows.append(.timeHeader)
        if timeOn { newRows.append(.timePicker) }
        
        if animated {
            tableView.performBatchUpdates({
                self.rows = newRows
                tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            })
        } else {
            rows = newRows
            tableView.reloadData()
        }
        emitCombined()
    }
    
    private func emitCombined() {
        // комбинируем текущую дату и время
        var comps = cal.dateComponents([.year,.month,.day], from: date)
        let t = cal.dateComponents([.hour,.minute], from: time)
        comps.hour = t.hour
        comps.minute = t.minute
        let combined = cal.date(from: comps) ?? date
        onChange?(combined)
    }
    
    // MARK: - Table
    
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let r = rows[indexPath.row]
        switch r {
        case .dateHeader:
            let cell = headerCell(title: "Дата", isOn: dateOn, detail: dateTitle(date))
            cell.accessoryType = .disclosureIndicator
            cell.switchAction = { [weak self] isOn in
                guard let self else { return }
                self.dateOn = isOn
                self.rebuildRows(animated: true)
            }
            return cell
        case .datePicker:
            let cell = pickerCell(mode: .date, date: date) { [weak self] newDate in
                guard let self else { return }
                self.date = newDate
                self.rebuildRows(animated: false)
            }
            return cell
        case .timeHeader:
            let cell = headerCell(title: "Время", isOn: timeOn, detail: timeOn ? timeTitle(time) : nil)
            cell.switchAction = { [weak self] isOn in
                guard let self else { return }
                self.timeOn = isOn
                if isOn { self.time = roundedTo15(Date()) }
                self.rebuildRows(animated: true)
            }
            return cell
        case .timePicker:
            let cell = pickerCell(mode: .time, date: time) { [weak self] newTime in
                guard let self else { return }
                self.time = self.roundedTo15(newTime)
                self.rebuildRows(animated: false)
            }
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let r = rows[indexPath.row]
        switch r {
        case .dateHeader:
            dateOn.toggle()
            rebuildRows(animated: true)
        case .timeHeader:
            timeOn.toggle()
            if timeOn { time = roundedTo15(Date()) }
            rebuildRows(animated: true)
        default: break
        }
    }
    
    // MARK: - Cells
    
    private func headerCell(title: String, isOn: Bool, detail: String?) -> HeaderCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HeaderCell.reuse, for: IndexPath(row: 0, section: 0)) as? HeaderCell
            ?? HeaderCell(style: .value1, reuseIdentifier: HeaderCell.reuse)
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = detail
        cell.configure(isOn: isOn)
        return cell
    }
    
    private func pickerCell(mode: UIDatePicker.Mode, date: Date, onChange: @escaping (Date)->Void) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: IndexPath(row: 0, section: 0))
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        let dp = UIDatePicker()
        dp.preferredDatePickerStyle = .inline
        dp.datePickerMode = mode
        dp.minuteInterval = 15
        if mode == .time { dp.locale = Locale(identifier: "ru_RU") }
        dp.date = date
        dp.addAction(UIAction { _ in onChange(dp.date) }, for: .valueChanged)
        cell.contentView.addSubview(dp)
        dp.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dp.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            dp.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            dp.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
            dp.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
        ])
        return cell
    }
    
    // MARK: - Helpers
    
    private func dateTitle(_ d: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        if Calendar.current.isDateInToday(d) { return "Сегодня" }
        if Calendar.current.isDateInTomorrow(d) { return "Завтра" }
        df.dateFormat = "EEEE, d MMMM yyyy"
        return df.string(from: d).capitalized
    }
    
    private func timeTitle(_ d: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "HH:mm"
        return df.string(from: d)
    }
    
    private func roundedTo15(_ d: Date) -> Date {
        let m = cal.component(.minute, from: d)
        let rounded = (m / 15) * 15
        let comps = cal.dateComponents([.year,.month,.day,.hour], from: d)
        return cal.date(from: DateComponents(year: comps.year, month: comps.month, day: comps.day, hour: comps.hour, minute: rounded)) ?? d
    }
}


