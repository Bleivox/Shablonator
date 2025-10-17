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
    
}
