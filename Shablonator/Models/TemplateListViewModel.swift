//
//  TemplateListViewModel.swift
//  Shablonator
//
//  Created by Никита Долгов on 13.10.25.
//

import Foundation
import Combine
import GRDB

final class TemplateListViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var templates: [Template] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""

    // MARK: - Private Properties
    private let repository: TemplateRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var filteredTemplates: [Template] {
        if searchText.isEmpty {
            return templates
        }
        return templates.filter { template in
            template.name.localizedCaseInsensitiveContains(searchText) ||
            template.description?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var hasTemplates: Bool {
        return !templates.isEmpty
    }

    var activeTemplatesCount: Int {
        return templates.filter { $0.stepCount > 0 }.count
    }

    // MARK: - Initialization
    init(repository: TemplateRepositoryProtocol = GRDBTemplateRepository()) {
        self.repository = repository
        setupBindings()
        loadTemplates()
    }

    // MARK: - Public Methods

    func loadTemplates() {
        isLoading = true
        errorMessage = nil

        repository.getAllTemplates()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        print("❌ Ошибка загрузки шаблонов: \(error)")
                    }
                },
                receiveValue: { [weak self] templates in
                    self?.templates = templates
                    print("✅ Загружено \(templates.count) шаблонов")
                }
            )
            .store(in: &cancellables)
    }

    func refreshTemplates() {
        loadTemplates()
    }

    func searchTemplates() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            loadTemplates()
            return
        }

        isLoading = true
        errorMessage = nil

        repository.searchTemplates(query: searchText)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] templates in
                    self?.templates = templates
                }
            )
            .store(in: &cancellables)
    }

    func selectTemplate(_ template: Template) {
        print("🎯 Выбран шаблон: \(template.name)")
        // TODO: Navigate to template details
    }

    func deleteTemplate(_ template: Template) {
        guard let id = template.id as? Int64 else { return }

        repository.deleteTemplate(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Ошибка удаления: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] _ in
                    print("✅ Шаблон '\(template.name)' удален")
                    self?.loadTemplates() // Перезагружаем список
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Реактивное обновление при изменении данных в БД
        repository.observeAllTemplates()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Ошибка наблюдения за шаблонами: \(error)")
                    }
                },
                receiveValue: { [weak self] templates in
                    self?.templates = templates
                }
            )
            .store(in: &cancellables)

        // Дебаунс поиска
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.searchTemplates()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Mock Data для тестирования
extension TemplateListViewModel {
    static var mock: TemplateListViewModel {
        let viewModel = TemplateListViewModel()
        viewModel.templates = Template.mockData
        return viewModel
    }
}
