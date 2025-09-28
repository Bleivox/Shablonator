//
//  DateTimePickerView.swift
//  Shablonator
//
//  Created by Никита Долгов on 19.09.25.
//

import UIKit
import SnapKit

final class DateTimePickerView: UIView {
    let daySegment = UISegmentedControl(items: ["Сегодня", "Завтра"])
    let picker = UIDatePicker()
    let quickStack = UIStackView()
    let gridStack = UIStackView()
    
    var onChange: ((Date) -> Void)?
    private let calendar = Calendar.current
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func setup() {
        daySegment.selectedSegmentIndex = 0
        daySegment.addTarget(self, action: #selector(dayChanged), for: .valueChanged)
        
        picker.preferredDatePickerStyle = .wheels
        picker.datePickerMode = .dateAndTime
        picker.minuteInterval = 15
        picker.addTarget(self, action: #selector(pickerChanged), for: .valueChanged)
        
        quickStack.axis = .horizontal
        quickStack.spacing = 8
        quickStack.distribution = .fillEqually
        
        gridStack.axis = .vertical
        gridStack.spacing = 8
        
        let vstack = UIStackView(arrangedSubviews: [daySegment, picker, quickStack, gridStack])
        vstack.axis = .vertical
        vstack.spacing = 12
        addSubview(vstack)
        vstack.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        // Быстрые кнопки
        ["+30 мин", "+1 ч", "+2 ч"].forEach { title in
            let b = makeChip(title)
            b.addAction(UIAction { [weak self] _ in self?.applyQuick(title) }, for: .touchUpInside)
            quickStack.addArrangedSubview(b)
        }
        
        rebuildGrid()
    }
    
    private func makeChip(_ title: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        b.backgroundColor = .secondarySystemBackground
        b.layer.cornerRadius = 8
        b.contentEdgeInsets = .init(top: 8, left: 12, bottom: 8, right: 12)
        return b
    }
    
    @objc private func dayChanged() {
        let base = Date()
        let target = daySegment.selectedSegmentIndex == 0
            ? base
            : calendar.date(byAdding: .day, value: 1, to: base)!
        let start = calendar.date(
            bySettingHour: max(calendar.component(.hour, from: base), 9),
            minute: (calendar.component(.minute, from: base) / 15) * 15,
            second: 0,
            of: target
        )!
        picker.setDate(start, animated: true)
        onChange?(picker.date)
        rebuildGrid()
    }
    
    @objc private func pickerChanged() {
        onChange?(picker.date)
    }
    
    private func applyQuick(_ title: String) {
        let add: TimeInterval
        switch title {
        case "+30 мин": add = 30 * 60
        case "+1 ч": add = 60 * 60
        default: add = 120 * 60
        }
        let newDate = picker.date.addingTimeInterval(add)
        // округляем к 15
        let comps = calendar.dateComponents([.year,.month,.day,.hour,.minute], from: newDate)
        let rounded = calendar.date(from: DateComponents(
            year: comps.year, month: comps.month, day: comps.day,
            hour: comps.hour, minute: (comps.minute!/15)*15))!
        picker.setDate(rounded, animated: true)
        onChange?(rounded)
        syncDaySegment(to: rounded)
    }
    
    private func syncDaySegment(to date: Date) {
        let isToday = calendar.isDateInToday(date)
        let isTomorrow = calendar.isDateInTomorrow(date)
        daySegment.selectedSegmentIndex = isToday ? 0 : (isTomorrow ? 1 : UISegmentedControl.noSegment)
    }
    
    private func rebuildGrid() {
        gridStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        // строим сетку 2x3 ближайших слотов по 15 минут
        let start = picker.date
        var slots: [Date] = []
        var t = start
        for _ in 0..<6 {
            t = t.addingTimeInterval(15*60)
            slots.append(t)
        }
        let rows = stride(from: 0, to: slots.count, by: 2).map { Array(slots[$0..<min($0+2, slots.count)]) }
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateFormat = "HH:mm"
        rows.forEach { row in
            let h = UIStackView()
            h.axis = .horizontal
            h.spacing = 8
            h.distribution = .fillEqually
            row.forEach { d in
                let b = makeChip(df.string(from: d))
                b.addAction(UIAction { [weak self] _ in
                    self?.picker.setDate(d, animated: true)
                    self?.onChange?(d)
                    self?.syncDaySegment(to: d)
                }, for: .touchUpInside)
                h.addArrangedSubview(b)
            }
            gridStack.addArrangedSubview(h)
        }
    }
}
