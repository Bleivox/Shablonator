//
//  StepsViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 05.09.25.
//
import UIKit
import SnapKit

final class StepsViewController: UIViewController {

    private let templateId: Int64
    private let repo = TemplateRepository()

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    init(templateId: Int64) {
        self.templateId = templateId
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        layout()
        loadData()
    }

    private func layout() {
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        scrollView.keyboardDismissMode = .onDrag

        scrollView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(16)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-32)
        }
    }

    private func loadData() {
        do {
            let steps = try repo.steps(for: templateId)
            render(steps)
        } catch {
            renderError(error)
        }
    }

    private func render(_ steps: [StepRecord]) {
        stackView.arrangedSubviews.forEach { v in
            stackView.removeArrangedSubview(v); v.removeFromSuperview()
        }
        if steps.isEmpty {
            let l = UILabel()
            l.text = "Шаги отсутствуют"
            l.textAlignment = .center
            l.textColor = .secondaryLabel
            stackView.addArrangedSubview(l)
            l.snp.makeConstraints { $0.height.greaterThanOrEqualTo(80) }
            return
        }

        for s in steps {
            let card = makeStepCard(s)
            stackView.addArrangedSubview(card)
        }
    }

    private func makeStepCard(_ s: StepRecord) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.secondarySystemBackground
        container.layer.cornerRadius = 12

        let title = UILabel()
        title.text = s.title
        title.font = .systemFont(ofSize: 18, weight: .semibold)

        let meta = UILabel()
        let flags = [
            s.isStart ? "start" : nil,
            s.isTerminal ? "terminal" : nil,
            s.kind
        ].compactMap { $0 }.joined(separator: " • ")
        meta.text = flags
        meta.textColor = .secondaryLabel
        meta.font = .systemFont(ofSize: 13)

        container.addSubview(title)
        container.addSubview(meta)
        title.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }
        meta.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview().inset(16)
        }
        return container
    }

    private func renderError(_ error: Error) {
        let l = UILabel()
        l.text = "Ошибка: \(error.localizedDescription)"
        l.textColor = .systemRed
        l.numberOfLines = 0
        stackView.addArrangedSubview(l)
    }
}
