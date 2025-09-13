//
//  UniversalCardConfigurator.swift
//  Shablonator
//
//  Created by Никита Долгов on 11.09.25.
//

import UIKit
import SnapKit

enum UniversalCardConfigurator {
    
    static func configure(containerView: UIView, titleLabel: UILabel, headerStackView: UIStackView, contentContainer: UIView, footerContainer: UIView, in rootView: UIView) {
        
        rootView.addSubview(containerView)
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        
        
        headerStackView.axis = .horizontal
        headerStackView.alignment = .center
        headerStackView.spacing = 12
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        
        containerView.addSubview(headerStackView)
        headerStackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }
        
        
        containerView.addSubview(contentContainer)
            contentContainer.snp.makeConstraints { make in
                make.top.equalTo(headerStackView.snp.bottom).offset(12)
                make.leading.trailing.equalToSuperview().inset(16)
                // НЕ задаём height - пусть определяется содержимым
            }
            
            containerView.addSubview(footerContainer)
            footerContainer.snp.makeConstraints { make in
                make.top.equalTo(contentContainer.snp.bottom).offset(8)
                make.leading.trailing.bottom.equalToSuperview().inset(16)
                // НЕ задаём height.greaterThanOrEqualTo(0) - это избыточно
            }
        
    }
    
}
