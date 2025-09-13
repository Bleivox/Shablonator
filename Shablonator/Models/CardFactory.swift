//
//  CardFactory.swift
//  Shablonator
//
//  Created by Никита Долгов on 11.09.25.
//

import UIKit

enum CardFactory {
    
    static func templateCard(
        title: String,
        stepCount: Int,
        hasVideo: Bool = false,
        onTap: @escaping () -> Void,
        onEdit: @escaping () -> Void
    ) -> UniversalCardView {
        let card = UniversalCardView()
        
        // Leading slot - иконка видео
        if hasVideo {
            let videoIcon = UIImageView(image: UIImage(systemName: "video.fill"))
            videoIcon.tintColor = .systemBlue
            card.leadingSlot = videoIcon
        }
        
        // Title
        card.titleText = title
        
        // Trailing slot - кнопка редактирования
        let editButton = UIButton(type: .system)
        editButton.setImage(UIImage(systemName: "pencil"), for: .normal)
        editButton.addAction(UIAction { _ in onEdit() }, for: .touchUpInside)
        card.trailingSlot = editButton
        
        // Content slot - количество шагов
        let stepLabel = UILabel()
        stepLabel.text = "\(stepCount) шагов"
        stepLabel.font = .systemFont(ofSize: 14)
        stepLabel.textColor = .secondaryLabel
        card.contentSlot = stepLabel
        
        // Callbacks
        card.onTap = onTap
        
        return card
    }
    
    static func stepCard(
        title: String,
        description: String,
        isCompleted: Bool = false,
        onTap: @escaping () -> Void
    ) -> UniversalCardView {
        let card = UniversalCardView()
        
        // Leading slot - статус
        let statusIcon = UIImageView(
            image: UIImage(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
        )
        statusIcon.tintColor = isCompleted ? .systemGreen : .systemGray3
        card.leadingSlot = statusIcon
        
        // Title
        card.titleText = title
        
        // Content slot - описание
        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 2
        card.contentSlot = descLabel
        
        card.onTap = onTap
        
        return card
    }
    
    static func customCard(
        title: String,
        leadingView: UIView? = nil,
        trailingView: UIView? = nil,
        contentView: UIView? = nil,
        footerView: UIView? = nil,
        onTap: (() -> Void)? = nil
    ) -> UniversalCardView {
        let card = UniversalCardView()
        card.titleText = title
        card.leadingSlot = leadingView
        card.trailingSlot = trailingView
        card.contentSlot = contentView
        card.footerSlot = footerView
        card.onTap = onTap
        return card
    }
}
