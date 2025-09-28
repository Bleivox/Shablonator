//
//  CardFactory.swift
//  Shablonator
//
//  Created by Никита Долгов on 11.09.25.
//


import UIKit
import SnapKit

enum CardFactory {

    static func templateCard(
        title: String,
        stepCount: Int,
        hasVideo: Bool,
        isSelected: Bool,
        onTap: @escaping () -> Void,
        onEdit: @escaping () -> Void
    ) -> UIView {

        let card = UniversalCardView()
        card.titleText = title

        // Метка с метаданными (шаги/видео)
        let meta = UILabel()
        meta.text = "\(stepCount) шагов" + (hasVideo ? " • Видео" : "")
        meta.textColor = .secondaryLabel
        meta.font = .systemFont(ofSize: 14)
        card.contentSlot = meta

        // Правая кнопка «Изменить»
        let editButton = UIButton(type: .system)
        editButton.setImage(UIImage(systemName: "pencil.circle"), for: .normal)
        editButton.tintColor = .tertiaryLabel
        editButton.accessibilityLabel = "Изменить"
        editButton.addAction(UIAction { _ in onEdit() }, for: .touchUpInside)
        card.trailingSlot = editButton

        // Визуальные состояния выделения
        card.layer.cornerRadius = 12
        card.layer.borderWidth = isSelected ? 2 : 1
        card.layer.borderColor = (isSelected ? UIColor.systemBlue : UIColor.separator).cgColor
        card.backgroundColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.12) : .secondarySystemBackground

        // Основной тап по карточке — выбор
        card.onTap = onTap
        return card
    }
}


private enum AssociatedKeys {
    // был: static var onTap = "onTap"
    static var onTap: UInt8 = 0 // тривиальный тип, фиксированный адрес
}


extension UIView {
    @objc func handleTap() {
        if let onTap = objc_getAssociatedObject(self, &AssociatedKeys.onTap) as? (() -> Void) {
            onTap()
        }
    }
}
