//
//  TemplateSearchManager.swift
//  Shablonator
//
//  Created by Никита Долгов on 15.09.25.
//

import UIKit
import Combine
import SnapKit


final class TemplateSearchManager: NSObject {

    private var allTemplates: [TemplateModel] = []
    private(set) var filteredTemplates: [TemplateModel] = []
    private var searchCancellable: AnyCancellable?
    private let searchSubject = PassthroughSubject<String, Never>()

    let searchBar = UISearchBar()
    weak var delegate: TemplateSearchDelegate?

    override init() {
        super.init()
        setupSearchBar()
        setupDebouncing()
    }

    func setTemplates(_ templates: [TemplateModel]) {
        allTemplates = templates
        filteredTemplates = templates
        delegate?.templateSearch(self, didUpdateResults: filteredTemplates)
    }

    // Вставка в любой контейнер — якоримся к top безопасной зоны
    func addToView(_ containerView: UIView) {
        containerView.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(containerView.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
    }
}

private extension TemplateSearchManager {

    func setupSearchBar() {
        searchBar.placeholder = "Поиск..."
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .clear
        searchBar.barTintColor = .clear
        searchBar.delegate = self

        let tf = searchBar.searchTextField
        tf.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.3)
        tf.layer.cornerRadius = 10
        tf.textColor = .label
        tf.leftView?.tintColor = .secondaryLabel
    }

    func setupDebouncing() {
        // Выполняем дебаунс на главном планировщике, чтобы безопасно обновлять UI
        searchCancellable = searchSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.performSearch(with: text)
            }
    }

    func performSearch(with text: String) {
        filteredTemplates = text.isEmpty
        ? allTemplates
        : allTemplates.filter {
            $0.title.localizedCaseInsensitiveContains(text) || "\($0.steps)".contains(text)
        }

        if filteredTemplates.isEmpty && !text.isEmpty {
            delegate?.templateSearchDidShowNoResults(self)
        } else {
            delegate?.templateSearch(self, didUpdateResults: filteredTemplates)
        }
    }
}

extension TemplateSearchManager: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange text: String) { searchSubject.send(text) }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { searchBar.resignFirstResponder() }
}
