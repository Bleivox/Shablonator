//
//  SummaryStepViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 18.09.25.
//

import UIKit
import SnapKit

final class SummaryStepViewController: UIViewController {
    
    private let step: StepRecord
    private let state: StepState
    private let onFinish: () -> Void
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let summaryLabel = UILabel()
    private let finishButton = UIButton(type: .system)
    
    init(step: StepRecord, state: StepState, onFinish: @escaping () -> Void) {
        self.step = step
        self.state = state
        self.onFinish = onFinish
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        generateSummary()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        titleLabel.text = step.title
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        summaryLabel.font = .systemFont(ofSize: 16)
        summaryLabel.textColor = .label
        summaryLabel.numberOfLines = 0
        summaryLabel.textAlignment = .left
        
        finishButton.setTitle("Готово", for: .normal)
        finishButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.backgroundColor = .systemGreen
        finishButton.layer.cornerRadius = 12
        finishButton.addAction(UIAction { [weak self] _ in
            self?.onFinish()
        }, for: .touchUpInside)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(summaryLabel)
        contentView.addSubview(finishButton)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        summaryLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        finishButton.snp.makeConstraints { make in
            make.top.equalTo(summaryLabel.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(56)
            make.bottom.lessThanOrEqualToSuperview().inset(32)
        }
    }
    
    private func generateSummary() {
        let values = state.getAllValues()
        var summary = "Итоговый текст на основе ваших ответов:\n\n"
        
        // Достаём дату
        let cal = Calendar.current
        var finalDate: Date?
        
        if let d = values["date"] as? Date {
            finalDate = d
        } else {
            // если сохранились только компоненты
            let now = Date()
            var comps = cal.dateComponents([.year, .month, .day], from: now)
            if let h = values["hour"] as? Int { comps.hour = h }
            if let m = values["minute"] as? Int { comps.minute = m }
            if comps.hour != nil || comps.minute != nil {
                finalDate = cal.date(from: comps)
            }
        }
        
        // Форматтеры
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateStyle = .long
        
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "ru_RU")
        timeFormatter.timeZone = TimeZone.current
        timeFormatter.dateFormat = "HH:mm"
        
        if let consultation = values["consultation"] as? String, consultation == "yes" {
//            summary += "Запись на консультацию\n"
            
            if let timeOfDay = values["timeOfDay"] as? String {
                summary += timeOfDay == "day" ? "Добрый день!\n" : "Добрый вечер!\n"
            }
            
            if let far = values["waiting"] as? Bool {
                summary += far ? "Приношу извинения за долгий ответ, была сильная загруженность на работе \nпоследние несколько дней 🙌🏻 " : "На консультацию могу предложить ближайшие даты: "
            }
            
            if let dateList = values["dates"] as? [Date], !dateList.isEmpty {
                let cal = Calendar.current
                let dayFmt = DateFormatter()
                dayFmt.locale = Locale(identifier: "ru_RU")
                dayFmt.dateFormat = "d MMMM yyyy"
                let timeFmt = DateFormatter()
                timeFmt.locale = Locale(identifier: "ru_RU")
                timeFmt.dateFormat = "HH:mm"
                
                let grouped = Dictionary(grouping: dateList) { d in
                    cal.startOfDay(for: d)
                }.sorted { $0.key < $1.key }
                
                var lines: [String] = []
                for (day, items) in grouped {
                    let times = items.sorted().map { timeFmt.string(from: $0) }.joined(separator: ", ")
                    lines.append("\(dayFmt.string(from: day)) в \(times)")
                }
                summary += "\nМогу предложить ближайшие варианты:\n- " + lines.joined(separator: "\n- ")
            }
            
            if let who = values["who"] as? String {
                summary += who == "self" ? "\nНапишите, пожалуйста, когда вам будет удобнее подойти + свои полные ФИО и дату рождения, я забронирую визит" : "Напишите, пожалуйста, когда будет удобнее подойти + ФИО, дату рождения и личный номер телефона человека, для которого бронируется визит"
            }
            summary += ".\n\nС уважением,\n"
            if let doc = values["signature"] as? String {
                summary += doc == "doctor" ? "Евгений Александрович, врач-стоматолог 🦷" : "Анастасия Алексеевна, врач-стоматолог 🦷"
            }
            
        } else {
            summary = "Спасибо за обращение!\nВозможно, в другой раз мы сможем помочь."
        }
        
        summaryLabel.text = summary
    }

}
