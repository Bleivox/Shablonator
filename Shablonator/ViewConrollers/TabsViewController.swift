//
//  TabsViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 14.06.25.
//
import UIKit
import SnapKit

final class TabsViewController: UIViewController {

    // UI
    private let header = UIView()
    private let titleLabel = UILabel()
    private let tabs: [Tab] = [
            .init(title: "Шаблоны", builder: { TemplatesViewController() }),
            .init(title: "Шаги",     builder: { StepsViewController() })
        ]
    private lazy var tabsView = UnderlineTabsView(items: tabs.map{ .init(title: $0.title) })
    private let container = UIView()

    // Контент
    private var current: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        TabsHeaderConfigurator.configure(header: header, titleLabel: titleLabel, tabs: tabsView, in: view)
        setupContainer()

        tabsView.onSelect = { [weak self] idx in self?.switchTo(idx) }
        switchTo(0) // стартовая вкладка
    }

    // MARK: UI

    private func setupContainer() {
        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: Switching

    private func switchTo(_ index: Int) {
        let next = tabs[index].builder()
        guard next !== current else { return }

        current?.willMove(toParent: nil)
        current?.view.removeFromSuperview()
        current?.removeFromParent()

        addChild(next)
        container.addSubview(next.view)
        next.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        next.didMove(toParent: self)
        current = next
    }
}
