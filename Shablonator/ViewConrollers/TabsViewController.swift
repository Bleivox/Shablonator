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
    private lazy var tabs = UnderlineTabsView(items: [
        .init(title: "Шаблоны"),
        .init(title: "Шаги")
    ])
    private let container = UIView()

    // Контент
    private let templatesVC = TemplatesViewController()
    private let stepsVC = StepsViewController()
    private var current: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupHeader()
        setupContainer()

        tabs.onSelect = { [weak self] idx in self?.switchTo(idx) }
        switchTo(0) // стартовая вкладка
    }

    // MARK: UI

    private func setupHeader() {
        // фон шапки + скругление верхних углов
        header.backgroundColor = UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(red: 0.08, green: 0.12, blue: 0.17, alpha: 1)
                : UIColor.systemGroupedBackground
        }
        header.layer.cornerRadius = 28
        header.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        header.layer.masksToBounds = true

        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            // низ задаём содержимым
        }

        titleLabel.text = "Сценарии"
        titleLabel.font = .systemFont(ofSize: 25, weight: .heavy)
        titleLabel.textColor = .label

        header.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
        }

        header.addSubview(tabs)
        tabs.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(4) // низ шапки = низ вкладок
        }
    }

    private func setupContainer() {
        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: Switching

    private func switchTo(_ index: Int) {
        let next = (index == 0) ? templatesVC : stepsVC
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
