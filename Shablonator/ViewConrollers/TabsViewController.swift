//
//  TabsViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 14.06.25.
//
import UIKit
import SnapKit

final class TabsViewController: UIViewController {

    // MARK: - UI
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let tabsView: UnderlineTabsView
    private let container = UIView()

    // MARK: - State
    private var currentChild: UIViewController?
    private var currentIndex: Int = 0
    private var selectedTemplateId: Int64?

    // MARK: - Tabs
    private struct Tab {
        let title: String
        let builder: () -> UIViewController
    }

    private var tabs: [Tab] {
        [
            Tab(title: "Шаблоны") { [weak self] in
                let vc = TemplatesViewController()
                vc.onSelectTemplate = { [weak self] (template: TemplateRecord) in
                    self?.selectedTemplateId = template.id
                    // Если пользователь на вкладке "Шаги", обновим её
                    if self?.currentIndex == 1 {
                        self?.switchTo(index: 1)
                    }
                }
                return vc
            },
            Tab(title: "Шаги") { [weak self] in
                if let id = self?.selectedTemplateId {
                    return StepsViewController(templateId: id)
                } else {
                    return PlaceholderViewController(text: "Выберите шаблон во вкладке «Шаблоны»")
                }
            }
        ]
    }

    // MARK: - Init
    init() {
        self.tabsView = UnderlineTabsView(items: [
            .init(title: "Шаблоны"),
            .init(title: "Шаги")
        ])
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupTabsCallback()
        switchTo(index: 0)
    }

    // MARK: - Setup UI
    private func setupUI() {
        // Используем ваш конфигуратор
        TabsHeaderConfigurator.configure(
            header: headerView,
            titleLabel: titleLabel,
            tabs: tabsView,
            in: view
        )

        // Контейнер для контента
        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func setupTabsCallback() {
        tabsView.onSelect = { [weak self] index in
            self?.switchTo(index: index)
        }
    }

    // MARK: - Tab management
    private func switchTo(index: Int) {
        currentIndex = index
        let newVC = tabs[index].builder()
        setChild(newVC)
    }

    private func setChild(_ vc: UIViewController) {
        // Удаляем старый child
        if let old = currentChild {
            old.willMove(toParent: nil)
            old.view.removeFromSuperview()
            old.removeFromParent()
        }

        // Добавляем новый child
        addChild(vc)
        container.addSubview(vc.view)
        vc.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        vc.didMove(toParent: self)
        currentChild = vc
    }
}
