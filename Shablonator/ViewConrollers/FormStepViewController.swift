//
//  FormStepViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 18.09.25.
//

import UIKit
import SnapKit

final class FormStepViewController: UIViewController {
    // Входные данные
    private let step: StepRecord
    private let repository: StepRepository
    private let onComplete: ([StepChoice]) -> Void
    
    // Данные формы
    private var variables: [VariableRecord] = []
    var fieldValues: [String: Any] = [:]
    
    // UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let fieldsStack = UIStackView()
    private let continueButton = UIButton(type: .system)
    
    // MARK: - Init
    init(step: StepRecord, repository: StepRepository, onComplete: @escaping ([StepChoice]) -> Void) {
        self.step = step
        self.repository = repository
        self.onComplete = onComplete
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadVariables()
    }
    
    // MARK: - UI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        titleLabel.text = step.title
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        fieldsStack.axis = .vertical
        fieldsStack.spacing = 16
        
        continueButton.setTitle("Продолжить", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.backgroundColor = .systemBlue
        continueButton.layer.cornerRadius = 12
        continueButton.addAction(UIAction { [weak self] _ in
            self?.handleContinue()
        }, for: .touchUpInside)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(fieldsStack)
        contentView.addSubview(continueButton)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(32)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        fieldsStack.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        continueButton.snp.makeConstraints {
            $0.top.equalTo(fieldsStack.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(56)
            $0.bottom.lessThanOrEqualToSuperview().inset(24)
        }
    }
    
    // MARK: - Data
    private func loadVariables() {
        do {
            variables = try repository.variables(for: step.id!)
            buildForm()
        } catch {
            print("Failed to load variables: \(error)")
        }
    }
    
    private func buildForm() {
        fieldsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let names = Set(variables.map { $0.name })
        let hasDateTimeTriple = names.contains("date") && names.contains("hour") && names.contains("minute")
        
        if hasDateTimeTriple {
            // Вставляем календарный UI наподобие Apple Calendar
            embedCalendarLikePicker()
            // Не создаем отдельные поля для date/hour/minute
            let rest = variables.filter { !["date","hour","minute"].contains($0.name) }
            rest.forEach { addField($0) }
        } else {
            // Обычная форма
            variables.forEach { addField($0) }
        }
    }
    
    private func embedCalendarLikePicker() {
        let vc = DateTimeCalendarController()
        addChild(vc)
        fieldsStack.addArrangedSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        vc.view.heightAnchor.constraint(greaterThanOrEqualToConstant: 320).isActive = true
        vc.didMove(toParent: self)
        
        vc.onChange = { [weak self] combined in
            guard let self else { return }
            self.fieldValues["date"] = combined
            let cal = Calendar.current
            self.fieldValues["hour"] = cal.component(.hour, from: combined)
            self.fieldValues["minute"] = cal.component(.minute, from: combined)
        }
    }
    
    private func addField(_ variable: VariableRecord) {
        let container = UIView()
        let label = UILabel()
        label.text = variable.name.capitalized
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        
        container.addSubview(label)
        label.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        
        let field = createInputField(for: variable)
        container.addSubview(field)
        field.snp.makeConstraints {
            $0.top.equalTo(label.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.greaterThanOrEqualTo(44).priority(750)
        }
        
        fieldsStack.addArrangedSubview(container)
    }
    
    // MARK: - Fields
    private func createInputField(for variable: VariableRecord) -> UIView {
        // Поддержка объединенного выбора (если такой тип будет в БД)
        if variable.type == "dateTimeCombo" || variable.name == "dateTime" {
            let v = DateTimePickerView()
            v.onChange = { [weak self] date in
                guard let self else { return }
                self.fieldValues["date"] = date
                let cal = Calendar.current
                self.fieldValues["hour"] = cal.component(.hour, from: date)
                self.fieldValues["minute"] = cal.component(.minute, from: date)
            }
            if let iso = variable.defaultValue,
               let d = ISO8601DateFormatter().date(from: iso) {
                v.picker.setDate(d, animated: false)
                v.onChange?(d)
            } else {
                v.onChange?(v.picker.date)
            }
            return v
        }
        
        switch variable.type {
        case "date":
            let datePicker = UIDatePicker()
            datePicker.datePickerMode = .date
            datePicker.preferredDatePickerStyle = .compact
            datePicker.addAction(UIAction { [weak self] _ in
                self?.fieldValues[variable.name] = datePicker.date
            }, for: .valueChanged)
            if let def = variable.defaultValue,
               let d = ISO8601DateFormatter().date(from: def) {
                datePicker.date = d
                fieldValues[variable.name] = d
            }
            return datePicker
            
        case "int":
            let tf = UITextField()
            tf.borderStyle = .roundedRect
            tf.keyboardType = .numberPad
            tf.placeholder = "Введите число"
            if let def = variable.defaultValue { tf.text = def }
            tf.addAction(UIAction { [weak self] _ in
                self?.fieldValues[variable.name] = Int(tf.text ?? "0") ?? 0
            }, for: .editingChanged)
            return tf
            
        default:
            let tf = UITextField()
            tf.borderStyle = .roundedRect
            tf.placeholder = "Введите текст"
            if let def = variable.defaultValue {
                tf.text = def
                fieldValues[variable.name] = def
            }
            tf.addAction(UIAction { [weak self] _ in
                self?.fieldValues[variable.name] = tf.text ?? ""
            }, for: .editingChanged)
            return tf
        }
    }
    
    // MARK: - Continue
    private func handleContinue() {
        let choices = fieldValues.map { StepChoice(key: $0.key, value: $0.value, label: nil) }
        onComplete(choices)
    }
}
