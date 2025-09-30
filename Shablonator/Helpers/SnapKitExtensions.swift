//
//  SnapKitExtensions.swift
//  Shablonator
//
//  Created by Никита Долгов on 29.09.25.
//

import UIKit
import SnapKit

// MARK: - UIView Extensions
extension UIView {
    
    // Базовые констрейнты
    func pinToSuperview(insets: UIEdgeInsets = .zero) {
        guard superview != nil else { return }
        snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(insets)
        }
    }
    
    func centerInSuperview() {
        guard superview != nil else { return }
        snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    func setSquareSize(_ size: CGFloat) {
        snp.makeConstraints { make in
            make.size.equalTo(size)
        }
    }
    
    // Стандартные лейауты
    func applyStandardPadding() {
        snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(DesignSystem.mediumPadding)
        }
    }
    
    func applyCardStyle() {
        backgroundColor = DesignSystem.cardColor
        layer.cornerRadius = DesignSystem.mediumRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
    }
    
    func applyHeaderLayout() {
        guard superview != nil else { return }
        snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(safeAreaLayoutGuide)
            make.height.equalTo(DesignSystem.tabBarHeight)
        }
    }
    
    func applyBottomBarLayout() {
        guard superview != nil else { return }
        snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(safeAreaLayoutGuide)
            make.height.equalTo(DesignSystem.tabBarHeight)
        }
    }
}

// MARK: - UIButton Extensions
extension UIButton {
    func applyPrimaryStyle() {
        backgroundColor = DesignSystem.primaryColor
        setTitleColor(.white, for: .normal)
        titleLabel?.font = DesignSystem.bodyFont.with(weight: .semibold)
        layer.cornerRadius = DesignSystem.smallRadius
        
        snp.makeConstraints { make in
            make.height.equalTo(DesignSystem.buttonHeight)
        }
    }
    
    func applySecondaryStyle() {
        backgroundColor = .clear
        setTitleColor(DesignSystem.primaryColor, for: .normal)
        titleLabel?.font = DesignSystem.bodyFont
        layer.borderColor = DesignSystem.primaryColor.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = DesignSystem.smallRadius
        
        snp.makeConstraints { make in
            make.height.equalTo(DesignSystem.buttonHeight)
        }
    }
    
    func applyFloatingActionButtonStyle() {
        backgroundColor = DesignSystem.primaryColor
        tintColor = .white
        setSquareSize(56)
        layer.cornerRadius = 28
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6
        layer.shadowOpacity = 0.15
    }
}

// MARK: - UITextField Extensions
extension UITextField {
    func applyStandardStyle() {
        backgroundColor = DesignSystem.cardColor
        font = DesignSystem.bodyFont
        borderStyle = .none
        layer.cornerRadius = DesignSystem.smallRadius
        layer.borderColor = UIColor.systemGray4.cgColor
        layer.borderWidth = 1
        
        // Внутренние отступы
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        leftViewMode = .always
        rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        rightViewMode = .always
        
        snp.makeConstraints { make in
            make.height.equalTo(DesignSystem.textFieldHeight)
        }
    }
}

// MARK: - UIStackView Extensions
extension UIStackView {
    func applyVerticalStyle(spacing: CGFloat = DesignSystem.smallPadding) {
        axis = .vertical
        distribution = .fill
        alignment = .fill
        self.spacing = spacing
    }
    
    func applyHorizontalStyle(spacing: CGFloat = DesignSystem.smallPadding) {
        axis = .horizontal
        distribution = .fillEqually
        alignment = .center
        self.spacing = spacing
    }
}

// MARK: - UIFont Extensions
extension UIFont {
    func with(weight: Weight) -> UIFont {
        return UIFont.systemFont(ofSize: pointSize, weight: weight)
    }
}
