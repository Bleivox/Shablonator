//
//  UnderlineTabsView.swift
//  Shablonator
//
//  Created by Никита Долгов on 04.09.25.
//
import UIKit
import SnapKit

final class UnderlineTabsView: UIView {
    
    
    // MARK: Public API
    var onSelect: ((Int) -> Void)?
    private(set) var selectedIndex: Int = 0

    // MARK: Style
    var accentColor: UIColor = .systemBlue { didSet { underline.backgroundColor = accentColor } }
    var activeColor: UIColor = .label       { didSet { updateButtonColors() } }
    var inactiveColor: UIColor = .secondaryLabel { didSet { updateButtonColors() } }
    var underlineHeight: CGFloat = 2 {
        didSet {
            underline.snp.updateConstraints { $0.height.equalTo(underlineHeight) }
            invalidateIntrinsicContentSize()
            requestLayout()
        }
    }
    var font: UIFont = .systemFont(ofSize: 20, weight: .semibold) {
        didSet {
            buttons.forEach { $0.titleLabel?.font = font }
            invalidateIntrinsicContentSize()
            requestLayout()
        }
    }

    // MARK: UI
    private let stack = UIStackView()
    private let underline = UIView()
    private var buttons: [UIButton] = []

    private var didAttachInitially = false

    // MARK: Init
    init(items: [Item], initialIndex: Int = 0) {
        super.init(frame: .zero)
        setupBase()
        apply(items: items, initialIndex: initialIndex)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Intrinsic size
    override var intrinsicContentSize: CGSize {
        let textHeight = font.lineHeight
        let total = textHeight + 6 + underlineHeight
        return CGSize(width: UIView.noIntrinsicMetric, height: ceil(total))
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil, !didAttachInitially, !buttons.isEmpty {
            attachUnderline(to: selectedIndex, animated: false)
            didAttachInitially = true
        }
    }

    // MARK: Public
    func apply(items: [Item], initialIndex: Int? = nil) {
        // очистка
        stack.arrangedSubviews.forEach { stack.removeArrangedSubview($0); $0.removeFromSuperview() }
        buttons.removeAll()
        didAttachInitially = false

        // индекс
        let start = initialIndex ?? selectedIndex
        selectedIndex = items.isEmpty ? 0 : max(0, min(start, items.count - 1))

        // кнопки
        for (i, item) in items.enumerated() {
            let b = UIButton(type: .system)
            b.setTitle(item.title, for: .normal)
            b.titleLabel?.font = font
            b.setTitleColor(i == selectedIndex ? activeColor : inactiveColor, for: .normal)
            b.tag = i
            b.addTarget(self, action: #selector(tap(_:)), for: .touchUpInside)
            buttons.append(b)
            stack.addArrangedSubview(b)
        }

        requestLayout()
    }

    func select(index: Int, animated: Bool = true, notify: Bool = true) {
        guard index != selectedIndex, index >= 0, index < buttons.count else { return }
        let old = selectedIndex
        selectedIndex = index
        updateButtonColors()

        attachUnderline(to: index, animated: animated && window != nil)

        UIView.transition(with: buttons[old], duration: 0.18, options: .transitionCrossDissolve, animations: nil)
        UIView.transition(with: buttons[index], duration: 0.18, options: .transitionCrossDissolve, animations: nil)

        if notify { onSelect?(index) }
    }

    // MARK: Private
    private func setupBase() {
        // стек
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 24

        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
            // низ задаст underline
        }

        // underline
        underline.backgroundColor = accentColor
        addSubview(underline)
        underline.snp.makeConstraints { make in
            make.top.equalTo(stack.snp.bottom).offset(6)
            make.bottom.equalToSuperview()
            make.height.equalTo(underlineHeight)
            make.leading.equalToSuperview() // временно; перецепим к titleLabel выбранной кнопки
            make.width.equalTo(0)
        }
    }

    private func updateButtonColors() {
        buttons.enumerated().forEach { i, b in
            b.setTitleColor(i == selectedIndex ? activeColor : inactiveColor, for: .normal)
        }
    }

    @objc private func tap(_ sender: UIButton) { select(index: sender.tag, animated: true) }

    private func attachUnderline(to index: Int, animated: Bool) {
        guard index < buttons.count, let label = buttons[index].titleLabel else { return }

        underline.snp.remakeConstraints { make in
            make.top.equalTo(stack.snp.bottom).offset(6)
            make.bottom.equalToSuperview()
            make.height.equalTo(underlineHeight)
            make.leading.equalTo(label.snp.leading)
            make.width.equalTo(label.snp.width)
        }

        let applyLayout = {
            self.setNeedsLayout()
            if self.window != nil { self.layoutIfNeeded() }
        }

        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: .curveEaseInOut, animations: applyLayout)
        } else {
            applyLayout()
        }
    }

    private func requestLayout() {
        setNeedsLayout()
        if window != nil { layoutIfNeeded() }
    }
}
