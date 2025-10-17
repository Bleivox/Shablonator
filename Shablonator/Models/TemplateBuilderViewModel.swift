//
//  TemplateBuilderViewModel.swift
//  Shablonator
//
//  Created by Никита Долгов on 13.10.25.
//

import Foundation
import Combine
import GRDB

final class TemplateBuilderViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var saveSuccess = false

    // MARK: - Properties
    private let repository: TemplateRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    /// Доступные переменные для шаблонов
    let availableVariables = [
        "patient_name",
        "patient_first_name",
        "patient_last_name",
        "appointment_date",
        "appointment_time",
        "doctor_name",
        "clinic_name",
        "clinic_phone",
        "clinic_address",
        "treatment_name",
        "cost_amount",
        "next_visit_date"
    ]

    // MARK: - Initialization
    init(repository: TemplateRepositoryProtocol = GRDBTemplateRepository()) {
        self.repository = repository
    }

    // MARK: - Public Methods

    /// Создать новый шаблон
    func createTemplate(_ template: Template, messageText: String) {
        isLoading = true
        errorMessage = nil
        saveSuccess = false

        repository.createTemplate(template)
            .flatMap { [weak self] savedTemplate -> AnyPublisher<Template, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "TemplateBuilder", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewModel deallocated"]))
                        .eraseToAnyPublisher()
                }

                // Создаем SMS шаг с сообщением
                let step = Step(
                    templateId: savedTemplate.id,
                    title: "SMS сообщение",
                    content: "Отправить SMS пациенту",
                    message: messageText,
                    kind: .sms,
                    isStart: true,
                    isTerminal: true,
                    sortHint: 1
                )

                return self.repository.addStepToTemplate(step: step)
                    .map { _ in savedTemplate }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false

                    switch completion {
                    case .finished:
                        self?.saveSuccess = true
                        print("✅ Шаблон '\(template.name)' создан успешно")

                    case .failure(let error):
                        self?.errorMessage = "Ошибка создания шаблона: \(error.localizedDescription)"
                        print("❌ Ошибка создания шаблона: \(error)")
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    /// Обновить существующий шаблон
    func updateTemplate(_ template: Template, messageText: String) {
        isLoading = true
        errorMessage = nil
        saveSuccess = false

        repository.updateTemplate(template)
            .flatMap { [weak self] updatedTemplate -> AnyPublisher<[Step], Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "TemplateBuilder", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewModel deallocated"]))
                        .eraseToAnyPublisher()
                }

                // Получаем существующие шаги для обновления
                return self.repository.getStepsForTemplate(id: updatedTemplate.id)
            }
            .flatMap { [weak self] existingSteps -> AnyPublisher<Step, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "TemplateBuilder", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewModel deallocated"]))
                        .eraseToAnyPublisher()
                }

                // Находим SMS шаг или создаем новый
                if let smsStep = existingSteps.first(where: { $0.kind == .sms }) {
                    // Обновляем существующий SMS шаг
                    var updatedStep = smsStep
                    updatedStep.message = messageText
                    updatedStep.updatedAt = Date()

                    return self.repository.updateStep(updatedStep)
                } else {
                    // Создаем новый SMS шаг
                    let newStep = Step(
                        templateId: template.id,
                        title: "SMS сообщение",
                        content: "Отправить SMS пациенту",
                        message: messageText,
                        kind: .sms,
                        isStart: true,
                        isTerminal: true,
                        sortHint: 1
                    )

                    return self.repository.addStepToTemplate(step: newStep)
                }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false

                    switch completion {
                    case .finished:
                        self?.saveSuccess = true
                        print("✅ Шаблон '\(template.name)' обновлен успешно")

                    case .failure(let error):
                        self?.errorMessage = "Ошибка обновления шаблона: \(error.localizedDescription)"
                        print("❌ Ошибка обновления шаблона: \(error)")
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    /// Получить описание переменной
    func getVariableDescription(_ variable: String) -> String {
        switch variable {
        case "patient_name":
            return "Полное имя пациента"
        case "patient_first_name":
            return "Имя пациента"
        case "patient_last_name":
            return "Фамилия пациента"
        case "appointment_date":
            return "Дата приема (дд.мм.гггг)"
        case "appointment_time":
            return "Время приема (чч:мм)"
        case "doctor_name":
            return "Имя врача"
        case "clinic_name":
            return "Название клиники"
        case "clinic_phone":
            return "Телефон клиники"
        case "clinic_address":
            return "Адрес клиники"
        case "treatment_name":
            return "Название процедуры"
        case "cost_amount":
            return "Стоимость лечения"
        case "next_visit_date":
            return "Дата следующего визита"
        default:
            return "Пользовательская переменная"
        }
    }

    /// Получить пример значения переменной
    func getVariableExample(_ variable: String) -> String {
        switch variable {
        case "patient_name":
            return "Иван Петров"
        case "patient_first_name":
            return "Иван"
        case "patient_last_name":
            return "Петров"
        case "appointment_date":
            return "15.10.2025"
        case "appointment_time":
            return "14:30"
        case "doctor_name":
            return "Доктор Смирнов"
        case "clinic_name":
            return "Стоматология 'Белая улыбка'"
        case "clinic_phone":
            return "+7 (495) 123-45-67"
        case "clinic_address":
            return "ул. Пушкина, д. 10"
        case "treatment_name":
            return "Лечение кариеса"
        case "cost_amount":
            return "5 000 ₽"
        case "next_visit_date":
            return "22.10.2025"
        default:
            return "Пример значения"
        }
    }

    /// Предварительный просмотр сообщения с подстановкой переменных
    func previewMessage(_ messageText: String) -> String {
        var previewText = messageText

        for variable in availableVariables {
            let placeholder = "{\(variable)}"
            let exampleValue = getVariableExample(variable)
            previewText = previewText.replacingOccurrences(of: placeholder, with: exampleValue)
        }

        return previewText
    }

    /// Валидация шаблона
    func validateTemplate(name: String, message: String) -> String? {
        // Проверка названия
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return "Введите название шаблона"
        }

        guard trimmedName.count >= 3 else {
            return "Название должно содержать минимум 3 символа"
        }

        guard trimmedName.count <= 100 else {
            return "Название не должно превышать 100 символов"
        }

        // Проверка сообщения
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else {
            return "Введите текст сообщения"
        }

        guard trimmedMessage.count >= 10 else {
            return "Сообщение должно содержать минимум 10 символов"
        }

        guard trimmedMessage.count <= 1000 else {
            return "Сообщение не должно превышать 1000 символов"
        }

        return nil // Валидация прошла успешно
    }

    /// Получить рекомендованные шаблоны сообщений
    func getRecommendedTemplates() -> [RecommendedTemplate] {
        return [
            RecommendedTemplate(
                title: "Напоминание о приеме",
                message: "Здравствуйте, {patient_name}! Напоминаем о записи на прием {appointment_date} в {appointment_time}. Ждем вас в {clinic_name}. Телефон: {clinic_phone}"
            ),
            RecommendedTemplate(
                title: "Подтверждение записи",
                message: "Уважаемый(ая) {patient_name}, ваша запись на {appointment_date} в {appointment_time} подтверждена. Адрес: {clinic_address}"
            ),
            RecommendedTemplate(
                title: "После лечения",
                message: "Здравствуйте, {patient_name}! Как ваше самочувствие после {treatment_name}? При любых вопросах обращайтесь: {clinic_phone}"
            ),
            RecommendedTemplate(
                title: "Счет за лечение",
                message: "{patient_name}, к оплате: {cost_amount} за {treatment_name}. Следующий визит: {next_visit_date}. Спасибо!"
            ),
            RecommendedTemplate(
                title: "Отмена приема",
                message: "Уважаемый(ая) {patient_name}, к сожалению, прием {appointment_date} в {appointment_time} отменен. Перезвоним для переноса: {clinic_phone}"
            )
        ]
    }
}

// MARK: - Supporting Models

struct RecommendedTemplate {
    let title: String
    let message: String
}
