//
//  UniversalCardView.swift
//  Shablonator
//
//  Created by Никита Долгов on 11.09.25.
//

import UIKit
import SnapKit

final class UniversalCardView: UIView {
    
    // MARK: - Slots
    var leadingSlot: UIView? { didSet { updateLeadingSlot() } }
    var titleText: String? { didSet { titleLabel.text = titleText } }
    var trailingSlot: UIView? { didSet { updateTrailingSlot() } }
    var contentSlot: UIView? { didSet { updateContentSlot() } }
    var footerSlot: UIView? { didSet { updateFooterSlot() } }
    
    // MARK: - Callbacks
    var onTap: (() -> Void)?
    
    // MARK: - UI Elements
    private weak var currentLeading: UIView?
    private weak var currentTrailing: UIView?
    
    private let containerView = UIView()
    private let headerStackView = UIStackView()
    private let titleLabel = UILabel()
    private let contentContainer = UIView()
    private let footerContainer = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        UniversalCardConfigurator.configure(
            containerView: containerView,
            titleLabel: titleLabel,
            headerStackView: headerStackView,
            contentContainer: contentContainer,
            footerContainer: footerContainer,
            in: self
        )

        // Гарантируем наличие заголовка в стеке
        if !headerStackView.arrangedSubviews.contains(titleLabel) {
            headerStackView.addArrangedSubview(titleLabel)
        }

        // Заголовок не должен исчезать при нехватке места
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        setupGestures()
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func cardTapped() {
        onTap?()
    }
}

extension UniversalCardView {
    
    private func updateLeadingSlot() {
            if let old = currentLeading {
                headerStackView.removeArrangedSubview(old)
                old.removeFromSuperview()
            }
            if let v = leadingSlot {
                headerStackView.insertArrangedSubview(v, at: 0)
                v.snp.makeConstraints { $0.size.equalTo(CGSize(width: 24, height: 24)) }
            }
            currentLeading = leadingSlot

            if !headerStackView.arrangedSubviews.contains(titleLabel) {
                headerStackView.insertArrangedSubview(titleLabel, at: currentLeading == nil ? 0 : 1)
            }
        }
    
    private func updateTrailingSlot() {
            if let old = currentTrailing {
                headerStackView.removeArrangedSubview(old)
                old.removeFromSuperview()
            }
            if let v = trailingSlot {
                headerStackView.addArrangedSubview(v)
                // Кнопка справа должна «держать» свой размер
                v.setContentHuggingPriority(.required, for: .horizontal)
                v.setContentCompressionResistancePriority(.required, for: .horizontal)
            }
            currentTrailing = trailingSlot
        }
    
    private func updateContentSlot() {
        contentContainer.subviews.forEach { $0.removeFromSuperview() }
        
        guard let contentSlot = contentSlot else { return }
        
        contentContainer.addSubview(contentSlot)
        contentSlot.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func updateFooterSlot() {
        footerContainer.subviews.forEach { $0.removeFromSuperview() }
        
        guard let footerSlot = footerSlot else { return }
        
        footerContainer.addSubview(footerSlot)
        footerSlot.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

