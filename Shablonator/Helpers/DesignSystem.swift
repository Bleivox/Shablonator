//
//  DesignSystem..swift
//  Shablonator
//
//  Created by Никита Долгов on 29.09.25.
//

import Foundation

import UIKit

struct DesignSystem {
    // Отступы
    static let smallPadding: CGFloat = 8
    static let mediumPadding: CGFloat = 16
    static let largePadding: CGFloat = 24
    static let extraLargePadding: CGFloat = 32
    
    // Радиусы скругления
    static let smallRadius: CGFloat = 8
    static let mediumRadius: CGFloat = 12
    static let largeRadius: CGFloat = 16
    
    // Размеры элементов
    static let buttonHeight: CGFloat = 44
    static let textFieldHeight: CGFloat = 48
    static let cardHeight: CGFloat = 100
    static let tabBarHeight: CGFloat = 60
    
    // Цвета
    static let primaryColor = UIColor.systemBlue
    static let secondaryColor = UIColor.systemGray
    static let backgroundColor = UIColor.systemBackground
    static let cardColor = UIColor.secondarySystemBackground
    
    // Шрифты
    static let titleFont = UIFont.systemFont(ofSize: 20, weight: .semibold)
    static let bodyFont = UIFont.systemFont(ofSize: 16, weight: .regular)
    static let captionFont = UIFont.systemFont(ofSize: 14, weight: .regular)
}
