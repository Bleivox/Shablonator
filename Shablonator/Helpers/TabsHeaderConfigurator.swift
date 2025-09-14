//
//  TabsHeaderConfigurator.swift
//  Shablonator
//
//  Created by Никита Долгов on 09.09.25.
//

import Foundation
import UIKit
import SnapKit

enum TabsHeaderConfigurator {
    
    static func configure(header: UIView, titleLabel: UILabel, tabs: UnderlineTabsView, in rootView: UIView) {
        
               header.backgroundColor = UIColor { tc in
                   tc.userInterfaceStyle == .dark
                       ? UIColor(red: 0.08, green: 0.12, blue: 0.17, alpha: 1)
                       : UIColor.systemGroupedBackground
               }
               header.layer.cornerRadius = 28
               header.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
               header.layer.masksToBounds = true

               rootView.addSubview(header)
               header.snp.makeConstraints { make in
                   make.top.equalTo(rootView.safeAreaLayoutGuide.snp.top)
                   make.leading.trailing.equalToSuperview()
               }

               titleLabel.font = .systemFont(ofSize: 32, weight: .heavy)
               titleLabel.textColor = .label
               titleLabel.text = "Сценарии"

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
                   make.bottom.equalToSuperview().inset(4)
               }
        
    }

}
